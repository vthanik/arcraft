/******************************************************************************* 
|
| Macro Name:      tu_pkcncderv.sas
|
| Macro Version:   3.5
|
| SAS Version:     9.4
|
| Created By:      Andrew Ratcliffe
|
| Date:            23-Dec-2004
|
| Macro Purpose:   This unit shall be a part of the creation suite of macros to 
|                  add derived variables in order to finalise the creation of the 
|                  PKCNC dataset (IDSL studies) or the ADPC dataset (CDISC studies).
| 
|                  The derivations to be applied are defined in the PKCNC dataset 
|                  specification.
|
|                  	PCPTMEN		PCRFDSDT	PCRFDSTM	PCRFDSDM
|                  	PCATMNUM	PCATMEN	  	PCATMU	  	PCSTDM
|                  	PCENDM		PCSTTMDV	PCENTMDV	PCTMDVU
|                  	PCCOM		PCDUR	    PCDURU	  	PCUAE
|                  	PCSTRESC	PCSTRESN	PCSTRESU	PCSTIMPN
|                  	PCRESIMP	PCLLQN	  	PCVOLU	  	PCNUMCOM
|                  	PCPROX		PCWNLN	  	PCWNLRT		PCSTIMSN
|			        PCATMC      PCWNLNU     PCUER
|
|                  This macro shall also perform imputations as specified in the 
|                  Standard Methods for the Non-Compartmental Analysis of 
|                  Pharmacokinetic Data[4], e.g. BLQs and populate the PCSTIMPN 
|                  variable. 
|
| Macro Design:    PROCEDURE STYLE MACRO
| 
| Input Parameters:
|
| NAME             DESCRIPTION                                     DEFAULT 
|
| DSETIN           Specifies the name of the input PK dataset      [blank] (Req)
|
| DSETINEXP        Specifies the name of the input exposure        ardata.exposure (Opt)
|                  dataset 
|
| DSETINPERIOD     Specifies the name of the input PERIOD          dmdata.period (Opt)
|                  dataset 
|
| DSETOUT          Specifies the name of the output dataset        ardata.pkcnc (Req)  [WJB1]
|                  to be created 
|
| JOINMSG          Specifies whether unmatched records in joins    WARNING (Opt)
|                  (e.g. PK/SMS2000) should be treated as warnings 
|                  or errors
|
| PCWTU            Specifies the value to be placed into the       g (Opt)
|                  PCWTU variable in all rows. Required if
|                  PCWTU is in the Dataset Plan 
|
| ELTMSTDUNIT      Specifies the units to which ELTMNUM values     HRS (Opt) 
|                  shall be standardised
|
|                  Valid values: SEC, MIN, HRS, DAY
|
| DVTMSTDUNIT      Specifies the units to which derived durations  HRS (Opt) 
|                  shall be standardised
|
|                  Valid values: SEC, MIN, HRS, DAY
|
| EXPJOINBYVARS    Specifies the variables by which the exp-       &g_subjid pernum period visitnum visit (Opt)
|                  osure dataset shall be merged with the PK data
|
| IMPUTEBY         Specifies the variables by which the imput-     &g_subjid pcspec pcan pernum visitnum pcrfdsdm ptmnum (Req) 
|                  ation shall be done. The dataset is sorted 
|                  prior to imputation using any vars in IMPUTEBY
|                  which are found in the dataset. Imputation is  
|                  then performed, restarting whenever any IMPUTEBY 
|                  variable other than the last one changes.              
| 
| IMPUTETYPE       Specifies either standard (S) or alternative    S (Req) 
|                  (A) imputation.
| 
| ADAMPARMVALS     Parameters to be derived if the macro is        [blank] (Opt) 
|                  called in CDISC mode (i.e. g_datatype=CDISC)
| 
| Output: The unit shall create the dataset specified by the DSETOUT parameter
|
| Global macro variables created:  None
|
| Macros called:  
| (@) tr_putlocals
| (@) tu_abort
| (@) tu_byid
| (@) tu_chknames
| (@) tu_chkvarsexist
| (@) tu_chkvartype
| (@) tu_isvarindsplan
| (@) tu_nobs
| (@) tu_putglobals
| (@) tu_readdsplan
| (@) tu_tidyup
| (@) tu_words
| (@) tu_xcpsectioninit
| (@) tu_xcpput
| (@) tu_xcpsectionterm
|
| Example:
|
| %tu_pkcncderv(DSETIN= work.temp
|              ,DSETOUT= work.pkcnc
|              );
|
|******************************************************************************* 
| Change Log 
|
| Modified By:  Trevor Welby            
| Date of Modification: 23-Dec-2004
| New version number: 01-001       
| Modification ID:  TQW9753.01-001
| Reason For Modification:  Add a validation check to test for the existence
|                           of BY variables on the Exposure Dataset (DSETINEXP)
|                           [Section 4]
|
| Modified By:  Trevor Welby            
| Date of Modification: 23-Dec-2004
| New version number: 01-002       
| Modification ID:  TQW9753.01-002
| Reason For Modification:  Change the default of JOINMSG Parameter to error
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     27-Jan-2005
| New version number:       01-003
| Modification ID:          
| Reason For Modification:  Ensure that all messages include &sysmacroname.
|                           When merging PK with Exposure, do not issue an xcp
|                           message for cases where no data from exposure.
|                           Make corrections to PCPERDY derivation. i) refer to
|                           PC variables instead of PK, and ii) remove the "+1"
|                           from the ELSE part of the derivation.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     02-Feb-2005
| New version number:       01-004
| Modification ID:          AR4
| Reason For Modification:  Amend derivation for PCPTMEN.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     03-Feb-2005
| New version number:       01-005
| Modification ID:          AR5
| Reason For Modification:  Add EXPJOINBYVARS parameter (removing need for allcols
|                            and foundcols code).
|                           Make DSETINEXP optional (only required if specific 
|                            variables are in the Dataset Plan).
|                           Use allcols/foundcols code for imputation sort.
|                           Fix imputation derivation with and & or clauses.
|                           Change derivations for PCATMNUM and PCATMEN.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     17-Feb-2005
| New version number:       01-006
| Modification ID:          AR6
| Reason For Modification:  Add PCTYPCD and PTMNUM to By vars for imputations.
|                           When deriving PCDUR, do not divide by 3600.
|                           Derive PCSTTMDV from ELTMSTN instead of eltmnum. Do 
|                            not divide by 3600. Move derivation of eltmstn before 
|                            derivation of pcsttmdv.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     07-Mar-2005
| New version number:       01-007
| Modification ID:          AR7
| Reason For Modification:  Fix imputation of PCWNLN: set "last row, not measurable" 
|                            to 0 instead of missing.
|                           Fix derivation of PCPERDY.
|                           Add code to take account of ineffectiveness of the EXIST
|                            function when given a blank dataset name (it uses _LAST_).
|                           Fix algorithm for foundcols.
|                           Add IMPUTEBY parameter, and fix imputation algorithms by
|                            using first. and last.
|                           Remove the null section for deriving perstady.
|                           Add check for existance of dsetinperiod dataset.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     10-Mar-2005
| New version number:       01-008
| Modification ID:          AR8
| Reason For Modification:  Add tu_abort after data steps with calls to stmt-style 
|                            macros.
|                           Reverse the change made in 01-007 so that "last row, 
|                            not measurable" is set to missing instead of 0 for PCWNLN.
|                           Check that PCSTIMP, PCRESIMP, and PCWNLN are in dsplan before
|                            imputing them. Check that required vars are available.
|                           Add validation for imputeby.
|                           For eltmstn, check that required vars are available.
|
| Modified By:              James McGiffen
| Date of Modification:     10-May-2005
| New version number:       01-009
| Modification ID:          JMcG9
| Reason For Modification:  1. Following UAT Change to imputation flag required.  
|                              Imputation flag should only been set for changes of NQ to 0 
|                           2. Technical issues 109 - removed reference to %tu_quotelist
|                              No modification id entered for this due to harp restrictions.
|
| Modified By:              Warwick Benger
| Date of Modification:     3-Oct-2008
| New version number:       02-001
| Modification ID:          WJB1
| Reason For Modification:  1.  Change to imputations for PCSTIMPN and PCWNLN defined in 
|                               updated PKOne document 
|                           2.  Inclusion of new imputed variable PCSTIMSN
|                           3.  New macro parameter IMPUTETYPE to specify Standard or Alternative
|                           4.  Check if EXSTTM exists (if not abort)
|                           5.  Creation of new variable PCATMC (PCATMNUM stated in HHh MMm format)
|                           6.  Definition of PCATMNUM, and imputation of PCSTIMPN, PCSTIMSN, PCWNLN
|                               for urine data                      
|                           7.  Modification of definition of PCWNLRT - always NULL if PCATMNUM is null
|                           8.  Change to default value for macro parameter IMPUTEBY
|                           9.  Move IMPUTEBY parameter validation to start of macro 
|                           10. Modify derived durations PCDUR PCPTMEN PCSTTMDV PCENTMDV and associated 
|                               units PCDURU PCTMDVU to units specified in DVTMSTDUNIT
|                           11. Modify derivation of PCPERDY to PCPERSDY and PCPEREDY 
|                               a/p DSM and ensure PERTSTDT is dropped after the merge
|
| Modified By:              Warwick Benger
| Date of Modification:     7-Jan-2013
| New version number:       03-001
| Modification ID:          WJB2
| Reason For Modification:  1.  Updated to allow variables required to be specified in ADAMPARVALS 
|                               if g_datatype=CDISC
|                           2.  Replace identification of urine records to PCSPEC="URINE"
|                           3.  Change so that PCRESIMP only "Y" where PCSTIMPN has been set to numeric 
|                               for non-numeric PCSTRESC
|                           4.  Refinement to derivation of PCATMC
|                           5.  Addition of derived variable PCUER and PCWNLU
|                           6.  Modification of derivation of PCSTIMPN, PCSTIMSN, PCWNLN for Urine
|
| Modified By:              Andrew Miskell
| Date of Modification:     1-Apr-2015
| New version number:       03-002
| Modification ID:          ATM1
| Reason For Modification:  1.  Changed order of certain derivations for dependencies.
|                           2.  Updated certain derivations for IDSL or CDISC-specific clauses.
|                           3.  Updated part of eltmStdUnit code to only execute for IDSL studies.
|                           4.  Add in run statements and start new data steps so macros resolve in correct order.
|
| Modified By:              Andrew Miskell
| Date of Modification:     1-Jun-2015
| New version number:       03-003
| Modification ID:          ATM1
| Reason For Modification:  1.  Changed calls and references to SUBJID to &G_SUBJID.
|
| Modified By:              Suzanne Brass
| Date of Modification:     12-Apr-2017
| New version number:       N/A
| Modification ID:          N/A
| Reason For Modification:  Updated SAS Version to 9.4
|
| Modified By:              Anthony J Cooper
| Date of Modification:     27-Sep-2017
| New version number:       03-004
| Modification ID:          AJC001
| Reason For Modification:  1) Fix typo in err(or) message
|                           2) Prevent un(initialised) variable messages by 
|                           using macro if statements where appropriate
|                           3) Derive PCUAE when required variables exist
|
| Modified By:              Anthony J Cooper
| Date of Modification:     29-May-2018
| New version number:       03-005
| Modification ID:          AJC002
| Reason For Modification:  1) For CDISC studies, ignore urine sample volume,
|                           weight and pH records when deriving PCUAE.
|                           2) Make exception report messages more meaningful 
|                           for CDISC studies.
|
********************************************************************************/ 

%macro tu_pkcncderv(
   DSETIN=                     /* type:ID Name of input DM PK dataset */
  ,DSETINEXP=ardata.exposure   /* type:ID Name of input A&R EXPOSURE dataset */
  ,dsetinperiod=dmdata.period  /* type:ID Name of input SI PERIOD dataset */
  ,DSETOUT=ardata.pkcnc        /* Output dataset */
  ,joinmsg=WARNING             /* Type of messages to be issued from joins (error or warning) */
  ,pcwtu=g                     /* Value to be placed into PCWTU variable */
  ,eltmstdunit=HRS             /* Units to which ELTMSTN values shall be standardised */
  ,dvtmstdunit=HRS             /* Units to which derived durations shall be standardised */
  ,expjoinbyvars=&g_subjid pernum period visitnum visit /* Variables by which exposure is merged with PK data */
  ,imputeby=&g_subjid pcspec pcan pernum visitnum pcrfdsdm ptmnum /* Variables to impute by */
  ,imputetype=S                /* Imputation type. Specifies either standard (S) or alternative (A) imputation */
  ,adamparmvals=               /* Values of PARAMCD to be included in ADaM dataset (g_type=CDISC) */
  );

  /*
  / Echo macro version number and values of parameters and global macro
  / variables to the log.
  /----------------------------------------------------------------------------*/
  %local MacroVersion /* Carries macro version number */
         prefix       /* Carries file prefix for work files */
         __debug_obs; /* Sets debug maximum number of observations */

  %let MacroVersion = 3 build 5;
  %let prefix=%substr(&sysmacroname,3);

  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_subjid g_datatype) 

  %if &g_debug ge 3 %then %let __debug_obs=obs=max;
  %else                   %let __debug_obs=obs=100;

  %let dsetin=%nrbquote(&dsetin.);
  %let dsetout=%nrbquote(&dsetout.);
  %let dsetinexp=%nrbquote(&dsetinexp.); 
  %let dsetinperiod=%nrbquote(&dsetinperiod.); 
  %if %length(&adamparmvals) gt 0 %then %let adamparmvals=%sysfunc(upcase(&adamparmvals));

  /*
  / PARAMETER VALIDATION
  /----------------------------------------------------------------------------*/
  /* 1. Check that DSETIN has been provided and exists [WJB1] */
  %if &dsetin. eq %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: The parameter DSETIN is required.;
    %let g_abort=1;
  %end;
  %else
  %do;  /* we have a DSETIN value */
    %if %sysfunc(exist(&dsetin., data)) ne 1 %then 
    %do;  /* Dataset does not exist */
      %put %str(RTE)RROR: &sysmacroname.: The dataset identified by DSETIN (&dsetin.) does not exist.;
      %let g_abort=1;
    %end; 
  %end; 
  
  /* 2. Check that DSETOUT has been provided and is a valid dataset [WJB1] */  
  %if &dsetout. eq %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: The parameter DSETOUT is required.;
    %let g_abort=1;
  %end;
  %else
  %do;  /* DSETOUT has a value */
    %if %nrbquote(%tu_chknames(&dsetout., data)) ne %then
    %do;  /* Dataset does not exist */
      %put %str(RTE)RROR: &sysmacroname.: The parameter DSETOUT (&dsetout.) is not a valid sas dataset name.;
      %let g_abort=1;
    %end; 
  %end; 
  
  /* 3. Check that DSETINEXP exists and contains EXSTTM [WJB1: brought up from normal processing] */
  %if &dsetinexp. eq %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: The parameter DSETINEXP is required.;
    %let g_abort=1;
  %end;
  %else
  %do;  /* we have a DSETINEXP value */
    %if %sysfunc(exist(&dsetinexp., data)) ne 1 %then 
    %do;  /* Dataset does not exist */
      %put %str(RTE)RROR: &sysmacroname.: The dataset identified by DSETINEXP (&dsetinexp.) does not exist.;
      %let g_abort=1;
    %end;
    %else 
    %do;
     %if %length(&expjoinbyvars) ne 0 %then 
     %do;  /* we have a valid DSETINEXP and EXPJOINBYVARS is not missing */
       %let colsNotExist=%tu_chkvarsexist(&DSETINEXP,&expjoinbyvars);
       %if %length(&colsNotExist) ne 0 %then /* one or more EXPJOINBYVARS do not exist on DSETINEXP */
       %do;
         %put RTE%str(RROR): &sysmacroname.: The following EXPJOINBYVARS variable(s) (%upcase(&colsNotExist.)) were not found in the DSETINEXP dataset (&dsetinexp);
         %let g_abort=1;
       %end;
     %end;
     %if %length(%tu_chkvarsexist(&dsetinexp,EXSTTM)) ne 0 %then
      %do;  /* we have a valid DSETINEXP but it does not contain EXSTTM */
        %put RTE%str(RROR): &sysmacroname: EXSTTM is not present in DSETINEXP (&dsetinexp);
        %let g_abort=1;
      %end; 
    %end; 
  %end;
  
  /* 4. Check that IMPUTEBY is not missing */   /* WJB1 */
  /* NOTE: Cannot check actual values until normal processing */
  %if %length(&imputeby) eq 0 %then 
  %do;
    %put RTE%str(RROR): &sysmacroname: The parameter IMPUTEBY is required; /* WJB1 */
    %let g_abort=1;
  %end;
  %else %do;
    %if %length(&dsetin) ne 0 %then  
    %do;  /* check IMPUTEBY variables exist either on DSETIN, or are PCRFDSDT or PCRFDSTM (which come from DSETINEXP) */
      %let colsNotExist=%sysfunc(tranwrd(%sysfunc(tranwrd(%sysfunc(tranwrd(%tu_chkvarsexist(&DSETIN,&imputeby),PCRFDSDT,)),PCRFDSTM,)),PCRFDSDM,));
      %if %length(&colsNotExist) ne 0 %then /* one or more IMPUTEBY vars do not exist either on DSETIN or DSETINEXP */
      %do;
         %put RTE%str(RROR): &sysmacroname.: The following IMPUTEBY variable(s) (%upcase(&colsNotExist.)) were not found in the DSETIN dataset (&dsetin);
         %let g_abort=1;
      %end;
    %end;
  %end;
  
  /* %tu_abort;  */ /* WJB1: continue with all parameter validation before aborting */

  /* 5. Check that some EXPJOINBYVARS have been provided */
  /* NOTE: Cannot check actual values until normal processing */
  %if %length(&expjoinbyvars) eq 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname: The parameter EXPJOINBYVARS is required;
    %let g_abort=1;
  %end;

  /* 6. Check imputetype is valid */   /* WJB1 */
  %if "&imputetype" ne "A" and "&imputetype" ne "S" %then 
  %do;
    %put RTE%str(RROR): &sysmacroname: IMPUTETYPE=&imputetype is not a valid selection. Valid values - either S or A;
    %let g_abort=1;
  %end;

  /* 7. If PERIOD dataset name has been provided, check that it exists 
  /  NOTE: Cannot check whether it should be provided until normal processing
  /-------------------------------------------------------------------------- */ /* WJB1 */
  %if %length(&dsetinperiod) gt 0 %then %do;
    %if not %sysfunc(exist(&dsetinperiod)) %then /*AR7*/
    %do;
      %put RTE%str(RROR): &sysmacroname: The specified DSETINPERIOD dataset (&dsetinperiod) does not exist;
      %let g_abort=1;
    %end;
  %end;

  /* 8. Check that ELTMSTDUNIT and DVTMSTDUNIT are valid
  / Check that ELTMSTDUNIT is valid 
  /-------------------------------------------------------------------------- */ /* WJB1 */
  %let eltmStdUnit = %upcase(&eltmStdUnit);
  %if &eltmStdUnit ne SEC and
      &eltmStdUnit ne MIN and
      &eltmStdUnit ne HRS and
      &eltmStdUnit ne DAY %then
  %do;
    %put RTE%str(RROR): &sysmacroname: The value specified for ELTMSTDUNIT (&eltmStdUnit) is not valid. It must be SEC, MIN, HRS, or DAY;
    %let g_abort = 1;
  %end;
  
  /* Check that DVTMSTDUNIT is valid */ /* WJB1 */
  %let dvtmstdUnit = %upcase(&dvtmstdUnit);
  %if &dvtmstdUnit ne SEC and
      &dvtmstdUnit ne MIN and
      &dvtmstdUnit ne HRS and
      &dvtmstdUnit ne DAY %then
  %do;
    %put RTE%str(RROR): &sysmacroname: The value specified for DVTMSTDUNIT (&dvtmstdUnit) is not valid. It must be SEC, MIN, HRS, or DAY;
    %let g_abort = 1;
  %end;

  /* 9. If type is CDISC, check that ADAMPARMVALS has been provided and DSETINPERIOD has not been provided
  /     Otherwise, check that ADAMPARMVALS has not been provided
  /-------------------------------------------------------------------------- */ /* WJB1 */

  %if &g_datatype eq CDISC %then %do;	         /* WJB2 */
    %if %length(&dsetinperiod) gt 0 %then 
    %do;
      %put RTE%str(RROR): &sysmacroname: DSETINPERIOD has been provided but the reporting type is CDISC;
      %let g_abort=1;
    %end;
    %if %length(&adamparmvals.) eq 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: The reporting type is CDISC, but ADAMPARMVALS has not been provided;
        %let g_abort = 1;
    %end;
  %end;
  %else %do;
    %if %length(&adamparmvals) gt 0 %then
    %do;
      %put RTE%str(RROR): &sysmacroname: ADAMPARMVALS has been provided but the reporting type is not CDISC;
      %let g_abort=1;
    %end;
  %end;

  /*
  / NORMAL PROCESSING
  /----------------------------------------------------------------------------*/
  /*
  / Plan of attack:  
  / 1. Load HARP Dataset Plan file into a dataset for subsequent   
  /    use (%tu_readdsplan)                                        
  / 2. If it is in the Dataset Plan, calculate PCPERDSY/PCPEREDY [WJB1]     
  / 3. If it is in the Dataset Plan, "calculate" PCWTU             
  / 4. Get variables from EXPOSURE dataset                         
  / 5. Add ELTMSTN/U                                               
  / 6. Calculate derived variables as required by the Dataset Plan                                       
  / 7. Deal with units/unit conversions
  / 8. Perform imputations                                          
  / 9. Create output dataset                                       
  / 10. Remove any temporary datasets (%tu_tidyup)                 
  / 11. Call %tu_abort()                                           
  /------------------------------------------------------*/

  %local currentDataset;
  %if %index(&dsetin,.) %then %let currentDataset = &dsetin;
  %else %let currentDataset = &dsetin;

  /*
  / 1. Load HARP Dataset Plan file into a dataset for subsequent   
  /    use (%tu_readdsplan)                                        
  /------------------------------------------------------*/
  %tu_readdsplan(dsetout=&prefix._dsplan);

  /*
  / 2. If in the Dataset Plan, calculate PCPERSDY/PCPEREDY  [WJB1]
  /
  / 2.1 Use DSETOUT from previous macro as input to DATA step
  / 2.2 Merge with DSETINPERIOD by &g_subjid and PERIOD in order to 
  /     keep PERTSTDT
  / 2.3 IF PKSTDT GE PERTSTDT: PKSTDT-PERIOD.PERTSTDT+1
  / 2.4 else IF PKSTDT LT PERTSTDT: PKSTDT-PERIOD.PERTSTDT
  / 2.5 Set attributes of the variable as per Dataset Plan
  /------------------------------------------------------*/
  /* Add PCPERSDY and PCPEREDY [WJB1]
  / Check that DSETINPERIOD contains PERTSTDT and        
  / check that DSETINPERIOD's PERTSTDT variable is numeric (%tu_chkvartype) 
  /------------------------------------------------------*/
  
  /* Check that DSETINPERIOD has been provided and the relevant
  /  variables are present to generate PCPERSDY and PCPEREDY 
  /------------------------------------------------------*/ /* WJB1 */
  %local varsdFound varedFound varsdAttrib varedAttrib vardNames;                                                

  %if &g_datatype eq IDSL %then %do;	     * WJB2 ;
    %let varsdFound = %tu_isvarindsplan(dsetin=&prefix._dsplan       
                                     ,var=PCPERSDY
                                     ,attribmvar=varsdAttrib);
    %let varedFound = %tu_isvarindsplan(dsetin=&prefix._dsplan       
                                     ,var=PCPEREDY
                                     ,attribmvar=varedAttrib);
  %end;
  %else %do;  
    %if %sysfunc(indexw(&adamparmvals,PCPERSDY)) %then %let varsdFound = Y;
    %if %sysfunc(indexw(&adamparmvals,PCPEREDY)) %then %let varedFound = Y;
  %end;
  

  %if &g_datatype eq IDSL and (&varsdFound eq Y or &varedFound eq Y) %then %do;  * PCPERSDY or PCPEREDY is in the Plan ;
    
    %if &varsdFound ne Y %then %do;        * PCPEREDY in plan ;
      %let vardNames=PCPEREDY is;            
    %end;
    %else %if &varedFound ne Y %then %do;  * PCPERSDY in plan ;
      %let vardNames=PCPERSDY is;        
    %end;
    %else %do;                             * both in plan ;
      %let vardNames=PCPERSDY and PCPEREDY are; 
    %end;
  
    /* Check that PERIOD dataset name has been provided ;*/
    %if %length(&dsetinperiod) eq 0 %then
    %do;
      %put RTN%str(OTE): &sysmacroname: &vardNames in Dataset Plan, but will not be derived because no PERIOD dataset specified on DSETINPERIOD parameter;
    %end;

    /* Check that PERTSTDT is in PERIOD dataset and is numeric ;*/
    %else %if %length(%tu_chkvarsexist(&dsetinperiod,PERTSTDT)) ne 0 %then
    %do; 
      %put RTE%str(RROR): &sysmacroname: &vardNames in Dataset Plan, but cannot be derived because variable PERTSTDT is not present in DSETINPERIOD (&dsetinperiod);
      %let g_abort = 1;
    %end;
    %else %if %tu_chkvartype(&dsetinperiod,PERTSTDT) ne N %then
    %do;
      %put RTE%str(RROR): &sysmacroname: &vardNames in Dataset Plan, but cannot be derived because the PERTSTDT variable in DSETINPERIOD (&dsetinperiod) is not numeric;
      %let g_abort = 1;
    %end;
    
    /* Check that PERNUM is in currentDataset ;*/
    %else %if %length(%tu_chkvarsexist(&currentDataset,PERNUM)) ne 0 %then
    %do;
      %put RTE%str(RROR): &sysmacroname: &vardNames in Dataset Plan, but cannot be derived because PERNUM is not present in DSETIN (&dsetin);
      %let g_abort = 1;
    %end;

    /* If all OK derive PCPERSDY and/or PCPEREDY ;*/
    %else 
    %do;
      proc sort data=&currentDataset out=&prefix._pksort;
        by &g_subjid pernum;
      run;

      proc sort data=&dsetinperiod out=&prefix._persort;
        by &g_subjid pernum;
      run;

      data &prefix._pcperdy10;
        merge &prefix._pksort (in=fromPk)
              &prefix._persort (in=fromPer)
              end=finish
              ;
        by &g_subjid pernum;
        attrib pcpersdy &varsdAttrib;
        attrib pcperedy &varedAttrib;
        drop __msg pertstdt; * WJB1 ;
        %tu_xcpsectioninit(header=Merge With PERIOD For PCPERSDY/PCPEREDY);    * WJB1 ;
        if pcstdt ge pertstdt then pcpersdy = PCSTDT-PERTSTDT+1;               * WJB1; 
        else pcpersdy = PCSTDT-PERTSTDT;                                       * WJB1; 
        if pcendt ge pertstdt then pcperedy = PCENDT-PERTSTDT+1;               * WJB1; 
        else pcperedy = PCENDT-PERTSTDT;                                       * WJB1; 
        if fromPk and not fromPer then
        do;
          %tu_byid(dsetin=&currentDataset
                  ,invars=&g_subjid pernum
                  ,outvar=__msg
                  );
          %tu_xcpput("Data from PK but not PERIOD: " !! __msg,&joinmsg);
        end;
        %tu_xcpsectionterm(end=finish);
        if not fromPk then DELETE; * left join ;
      run;
      %let currentDataset = &prefix._pcperdy10;
    %end;

  %end; /* PCPERSDY or PCPEREDY is in the Plan */

  /*
  / 3. Set PCWTU             
  /
  / 3.1 Check that the parameter is not blank
  / 3.2 Set attributes of the variable as per Dataset Plan
  / 3.3 Set the value of the variable equal to the value of the 
  /     PCWTU parameter
  /------------------------------------------------------*/
  %local varFound varAttrib;

  %if &g_datatype eq IDSL %then %do;	      * WJB2 ;
    %let varFound = %tu_isvarindsplan(dsetin=&prefix._dsplan
                                     ,var=PCWTU
                                     ,attribmvar=varAttrib
                                     );
  %end;
  %else %do;
    %if %sysfunc(indexw(&adamparmvals,PCWTU)) %then %let varFound = Y;
  %end; 
  
  %if &varFound eq Y %then %do;  * Need to add PCWTU ;
    data &prefix._pcwtu10;
      set &currentDataset;
      length pcwtu $ 20;
      pcwtu="&pcwtu";
    run;
    %let currentDataset=&prefix._pcwtu10;
  %end; /* Need to add PCWTU */

  /* 4. Get variables from EXPOSURE dataset */    /*AR5*/
  /* PCRFDSDT EXPOSURE.EXSTDT
  /  Merge PK and EXPOSURE by EXPJOINBYVARS
  /  Set PCRFDSDT=EXPOSURE.EXSTDT 
  /  Set PCRFDSTM=EXPOSURE.EXSTTM  
  /  Create PCRFDSDM from PCRFDSDT and PCRFDSTM
  /------------------------------------------------------*/

  /*
  /  Check that the EXPJOINBYVARS variables exist in the the prevailing dataset
  /  [TQW9753.01-001]  AR5
  /----------------------------------------------------------------------------- */
  %local colsNotExist;

  %let colsNotExist=%tu_chkvarsexist(&currentDataset,&expjoinbyvars);
  %if %length(&colsNotExist) ne 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: The following EXPJOINBYVARS variable(s) (%upcase(&colsNotExist.)) were not found in the prevailing work dataset (&currentDataset);
    %tu_abort(option=force);
  %end;

  /* Now perform the MERGE (PK left join EXPOSURE) */
  proc sort data=&currentDataset out=&prefix._in10;
    by &expjoinbyvars;
  run;

  proc sort data=&dsetinexp out=&prefix._exp10;
    by &expjoinbyvars;
  run;
  
  /* Check in DSETINEXP for instances of EXPJOINBYVARS with >1 record, and return warning as required */
  proc sort data=&prefix._exp10 out=&prefix._exp10_nodups nodupkeys;
    by &expjoinbyvars;
  run;    
  %if %tu_nobs(&prefix._exp10) ne %tu_nobs(&prefix._exp10_nodups) %then %do;
    %put RTE%str(RROR): &sysmacroname: There are duplicate values of EXPJOINBYVARS (&expjoinbyvars) in DSETINEXP (&dsetinexp).;
    %tu_abort(option=force);
  %end;
  
  data &prefix._inexp10;
    merge &prefix._in10 (in=fromPk)
          &prefix._exp10 (in=fromExp
                               keep=&expjoinbyvars
                                    exstdt exsttm
                              )
          end=finish
          ;
    by &expjoinbyvars;
    attrib PCRFDSDM format=datetime15.;
    rename exstdt=pcrfdsdt
           exsttm=pcrfdstm;
    drop __msg;

    %tu_xcpsectionInit(header=Merge with EXPOSURE);

    if (fromPk and not fromExp) or (fromExp and not fromPk) then
    do;

      if fromPk and not fromExp then
      do;

        %tu_byid(dsetin=&prefix._in10
                ,invars=&expjoinbyvars
                ,outvar=__msg
                );

        %tu_xcpput("Data from PK but not Exposure: " !! __msg,&joinmsg);

      end;

    end;
    else
    do;
      PCRFDSDM=dhms(exstdt,hour(exsttm)
                          ,minute(exsttm)
                          ,second(exsttm)
                          );
    end;

    %tu_xcpsectionTerm(end=finish);

    if fromExp and not fromPk then
    do;
      DELETE;
    end;
  run;
  %tu_abort;

  %let currentDataset = &prefix._inexp10;

  %if &g_debug ge 1 %then
  %do;
    title "RTD" "EBUG: &sysmacroname: Output dataset (&currentDataset) "
          'from merge with exposure';
    proc contents data=&currentDataset;
    run;
  %end;
  %if &g_debug ge 2 %then
  %do;
    title "RTD" "EBUG: &sysmacroname: Output dataset (&currentDataset, &__debug_obs) "
          'from merge with exposure';
    proc print data=&currentDataset (&__debug_obs);
    run;
  %end;

  /* 5. Add ELTMSTN/U */
  %let thisVar = ELTMSTN;
  
  %if &g_datatype eq IDSL %then %do;	   * WJB2 ;
    %let varFound = %tu_isvarindsplan(dsetin=&prefix._dsplan,var=&thisVar);
  %end;
  %else %do;
    %if %sysfunc(indexw(&adamparmvals,&thisVar)) %then %let varFound = Y;
    %else %let varfound = N;
  %end;  
  
  %if &varFound eq Y %then %do;

    %if %length(&eltmStdUnit) eq 0 %then
    %do;
      %put RTE%str(RROR): &sysmacroname: Cannot derive &thisVar because the ELTMSTDUNIT parameter is blank. It should be SEC, MIN, HRS, or DAY;
      %tu_abort(option=force);
    %end;

    %let reqdVars = ELTMUNIT ELTMNUM;  /*AR8*/
    %let missingVars = %tu_chkvarsexist(&currentDataset,&reqdVars);
    %if %length(&missingVars) gt 0 %then
    %do;
      %put RTE%str(RROR): &sysmacroname: Cannot derive &thisVar (as required by Dataset Plan) because source variables are missing: &missingVars;
      %tu_abort(option=force);
    %end;

    data &prefix._eltmst;
      set &currentDataset end=finish;
      drop __msg;

    /* For the purpose of calculations, create ELTMSTN in units of hours 
    /  (ELTMSTN will later be reconverted to units specified in ELTMSTDUNIT  
    /----------------------------------------------------------------------*/ /* WJB1 */
      /* AJC002: augment exception report header for CDISC studies */
      %if &g_datatype eq IDSL %then
        %tu_xcpSectionInit(header=Derive ELTMSTN);
      %else
        %tu_xcpSectionInit(header=Derive ELTMSTN (will be renamed to APRELTM in ADaM));
      eltmstu = "HRS";
      select (eltmunit);
        when ('DAY')
        do;  
          %str(eltmstn = eltmnum * 24;);
        end; /* day */
        when ('HRS')
        do;  /* hrs */
          %str(eltmstn = eltmnum;);
        end; /* hrs */
        when ('MIN')
        do;  /* min */
          %str(eltmstn = eltmnum / 60;);
        end; /* min */
        when ('SEC')
        do;  /* sec */
          %str(eltmstn = eltmnum / 3600;);
        end; /* sec */
        otherwise
        do;
        %if &g_datatype eq CDISC and %length(%tu_chkvarsexist(&currentDataset, PCELTM)) eq 0 %then 
        %do;
          %tu_byid(dsetin=&currentDataset
                  ,invars=&g_subjid eltmnum
                  ,outvar=__msg
                  );
          %tu_xcpput("Cannot derive ELTMSTN for " !! trim(__msg)
                     !! ". Invalid unit in ELTMUNIT: " !! eltmunit
                     || ". Check value of PCELTM in SDTM."
                    ,&joinmsg
                    );
        %end; /* AJC002: augment exception report message for CDISC studies */
        %else
        %do;
          %tu_byid(dsetin=&currentDataset
                  ,invars=&g_subjid eltmnum
                  ,outvar=__msg
                  );
          %tu_xcpput("Cannot derive ELTMSTN for " !! trim(__msg)
                     !! ". Invalid unit in ELTMUNIT: " !! eltmunit
                    ,&joinmsg
                    );
        %end;
        end;
      end;
      %tu_xcpSectionTerm(end=finish);
    run;
    %tu_abort;
    %let currentDataset=&prefix._eltmst;
  %end; /* add eltmstn/u */

/* Create incurine - identifies whether urine records are present */   /* WJB1 */
  %local incurine;
  %let incurine = N;
  data _null_;
    set &currentDataset;
    /* AJC001: Prevent un(initialised) variable messages */
    %if &g_datatype eq IDSL %then
    %do;
      if pctypcd='2' then call symput('incurine',"Y");   /* ATM1 */
    %end;
    %else
    %do;
      if upcase(pcspec) eq "URINE" then call symput('incurine',"Y");   /* ATM1 */
    %end;
  run;

/* 6. Calculate derived variables as required by the Dataset Plan */
  %local thisVar derivation reqdVars varAttrib missingVars /* WJB1 */ derivation2 reqdVars2 missingVars2 /* WJB1 */;
  
  data &prefix._10;
    set &currentDataset;

    %let thisVar = PCATMEN;
	
    %if &g_datatype eq IDSL %then %do;	          * WJB2 ;
      %let varFound = %tu_isvarindsplan(dsetin=&prefix._dsplan,var=&thisVar,attribmvar=varAttrib);
    %end;
    %else %do;
      %if %sysfunc(indexw(&adamparmvals,&thisVar)) %then %let varFound = Y;
      %else %let varfound = N;
    %end;  
	
    %let derivation = (dhms(PCENDT,0,0,PCENTM) - dhms(PCRFDSDT,0,0,PCRFDSTM))/3600;
    %let reqdVars = PCENDT PCENTM PCRFDSDT PCRFDSTM;
    %if &varFound eq Y %then %do;
      
      %if &g_datatype eq IDSL %then attrib &thisVar &varAttrib;;	   /* WJB2 */
	  
      %let missingVars = %tu_chkvarsexist(&currentDataset,&reqdVars);
      %if %length(&missingVars) gt 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: Cannot derive &thisVar (as required by Dataset Plan) because source variables are missing: &missingVars;
        call symput('G_ABORT','1');
      %end;
      %else
      %do;
        &thisVar = &derivation;
      %end;
    %end;
    %else
    %do;
      %if &g_debug ge 1 %then
        %put RTD%str(EBUG): &sysmacroname: Will not derive &thisVar (not in Dataset Plan);
    %end;

    /* PCATMNUM [non-urine: WJB1] Derive: (dhms(PCSTDT,0,0,PCSTTM) - dhms(PCRFDSDT,0,0,PCRFDSTM))/3600 */ /*AR5*/
    /* PCATMNUM [urine] Derive: (((dhms(PCSTDT,0,0,PCSTTM)+ dhms(PCENDT,0,0,PCENTM))/2) - dhms(PCRFDSDT,0,0,PCRFDSTM))/3600  */ /* WJB1 */
    %let thisVar = PCATMNUM;
	
    %if &g_datatype eq IDSL %then %do;	        /* WJB2 */
      %let varFound = %tu_isvarindsplan(dsetin=&prefix._dsplan,var=&thisVar,attribmvar=varAttrib);
    %end;
    %else %do;
      %if %sysfunc(indexw(&adamparmvals,&thisVar)) %then %let varFound = Y;
      %else %let varfound = N;
    %end;  
	
    %let derivation = (dhms(PCSTDT,0,0,PCSTTM) - dhms(PCRFDSDT,0,0,PCRFDSTM))/3600; /* WJB1: non-urine */
    %let derivation2 = (((dhms(PCSTDT,0,0,PCSTTM)+ dhms(PCENDT,0,0,PCENTM))/2) - dhms(PCRFDSDT,0,0,PCRFDSTM))/3600;  /* WJB1: urine */
    %let reqdVars = PCSTDT PCSTTM PCRFDSDT PCRFDSTM;
    %let reqdVars2 = PCENDT PCENTM;  /* WJB1 */
    %if &varFound eq Y %then %do;
	  
      %if &g_datatype eq IDSL %then attrib &thisVar &varAttrib;;	      /* WJB2 */
	  
      %let missingVars = %tu_chkvarsexist(&currentDataset,&reqdVars);
      %let missingVars2 = %tu_chkvarsexist(&currentDataset,&reqdVars2);
      %if %length(&missingVars) gt 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: Cannot derive &thisVar (as required by Dataset Plan) because source variables are missing: &missingVars;
        call symput('G_ABORT','1');
      %end;
      %else %if "&incurine"="Y" and %length(&missingVars2) gt 0 %then  /* WJB1 */
      %do;
        %put RTE%str(RROR): &sysmacroname: Cannot derive &thisVar (as required by Dataset Plan) for Urine PK because source variables are missing: &missingVars2;
        call symput('G_ABORT','1');
      %end;
      %else
      %do;
        /* AJC001: Prevent un(initialised) variable messages */
        %if &g_datatype eq IDSL %then
        %do;
          if pctypcd^='2' then &thisVar = &derivation;  /* ATM1 */
        %end;
        %else
        %do;
          if upcase(pcspec) ne "URINE" then &thisVar = &derivation;  /* ATM1 */
        %end;
          else &thisVar = &derivation2;                   /* WJB1 */
      %end;
    %end;
    %else
    %do;
      %if &g_debug ge 1 %then
        %put RTD%str(EBUG): &sysmacroname: Will not derive &thisVar (not in Dataset Plan);
    %end;
  run;
  %tu_abort;

  %let currentDataset=&prefix._10;

  /* Start new data step so macros resolve in correct order */ /* ATM1 */
  data &prefix._11;
    set &currentDataset;

    /* 
    /  Additional code for calculation of PCATMC
    /  [WJB5671.01-010]  WJB1
    /------------------------------------------------------*/

    /* PCATMC [urine] Derive: int(pcatmnum)||"h "(pcatmnum-int(pcatmnum))*60||"m"  */
    %let thisVar = PCATMC;
    %let reqdVars = PCATMNUM;
    %if %length(%tu_chkvarsexist(&currentDataset,PCATMNUM)) ne 0 %then
    %do; 
      %put RTE%str(RROR): &sysmacroname: PCATMC will not be derived due to PCATMNUM not being present in the data;
      %let g_abort = 1;
    %end;
    %else %do;
      %local pcatsign pcath pcatm;
      %let pcatsign = substr(put(repeat('-',(sign(pcatmnum)-1)/-2),$2.),2,1);
      %let pcath = right(right(compbl(&pcatsign)) || left(abs(int(pcatmnum)))) || "h";
      %let pcatm     = put(put(abs((pcatmnum-int(pcatmnum)))*60,2.)||left("m"),$3.);
      %let derivation = right(put(right(compbl(&pcath)) || " " || right(&pcatm),$10.));
      %let missingVars = %tu_chkvarsexist(&currentDataset,&reqdVars);
      if pcatmnum ne . then &thisVar = &derivation;
      length tu_pkcncderv_pcatm $ 30;
      tu_pkcncderv_pcatm=&pcatm;
      if tu_pkcncderv_pcatm eq "60m" then do;
        tu_pkcncderv_pcatm = " 0m";
        PCATMC_temp=right(put(right(compbl(&pcatsign)) || left(abs(int(pcatmnum)+1)),$5.)) || "h";
        pcatmc=right(trim(PCATMC_temp || " " || tu_pkcncderv_pcatm));
      end;
      drop tu_pkcncderv_pcatm PCATMC_temp;
    %end;
    
    /* PCATMU hard-code as HRS */
    %let thisVar = PCATMU;
    %let derivation = "HRS";
    %if &g_datatype eq IDSL %then %do;	       /* WJB2 */
      %let varFound = %tu_isvarindsplan(dsetin=&prefix._dsplan,var=&thisVar,attribmvar=varAttrib);
    %end;
    %else %do;
      %if %sysfunc(indexw(&adamparmvals,&thisVar)) %then %let varFound = Y;
      %else %let varfound = N;
    %end;  
    %if &varFound eq Y %then %do;
      %if &g_datatype eq IDSL %then attrib &thisVar &varAttrib;;	   /* WJB2 */
      &thisVar = &derivation;
    %end;
    %else
    %do;
      %if &g_debug ge 1 %then
        %put RTD%str(EBUG): &sysmacroname: Will not derive &thisVar (not in Dataset Plan);
    %end;

   /* PCWNLRT: Equals pcatmnum, unless value is negative, in which case it should be zero
   /  or if PCATMNUM is missing, PCWNLRT should be missing  [WJB1]
   /-------------------------------------------------------------------------------------- */
    %let thisVar = PCWNLRT;
    %let derivation = pcatmnum - pcatmnum + max(0,pcatmnum); /* WJB1 - (pcatmnum - pcatmnum) will force it evaluate to missing if pcatmnum is missing */
    %let reqdVars = PCATMNUM;
    &thisVar = &derivation;

    /* PCDUR Derive: (dhms(PCENDT,0,0,PCENTM)-dhms(PCSTDT,0,0,PCSTTM)+60)/3600 */ /* WJB1 */
    %let thisVar = PCDUR;
    %let derivation = (dhms(PCENDT,0,0,PCENTM)-dhms(PCSTDT,0,0,PCSTTM)+60)/3600; /* WJB1 */
    %let reqdVars = PCENDT PCENTM PCSTDT PCSTTM; /* WJB1 */
    %if (("&g_datatype"="IDSL" and Y eq %tu_isvarindsplan(dsetin=&prefix._dsplan,var=&thisVar,attribmvar=varAttrib))  or ("&g_datatype"="CDISC" and %tu_chkvarsexist(&dsetin,PCENDTC) = )) %then
    %do;  /* Var is in plan */  /* ATM1 */
      %if ("&g_datatype"="IDSL") %then %do; attrib &thisVar &varAttrib; %end;
      %else %do; attrib PCDUR label='Urine Collection Duration';  %end;
      %let missingVars = %tu_chkvarsexist(&currentDataset,&reqdVars);
      %if %length(&missingVars) gt 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: Cannot derive &thisVar (as required by Dataset Plan) because source variables are missing: &missingVars;
        call symput('G_ABORT','1');
      %end;
      %else
      %do;
        &thisVar = &derivation;
      %end;
    %end;
    %else
    %do;
      %if &g_debug ge 1 %then
        %put RTD%str(EBUG): &sysmacroname: Will not derive &thisVar (not in Dataset Plan);
    %end;
    
    /* PCDURU hard-code as HRS */
    %let thisVar = PCDURU;
    %let derivation = "%qupcase(&dvtmstdunit)";
    &thisVar = &derivation;

    /* PCSTDM Created from PCSTDT and PCSTTM */
    %let thisVar = PCSTDM;
    %let derivation = dhms(pcstdt,hour(pcsttm)
                          ,minute(pcsttm)
                          ,second(pcsttm)
                          );
    %let reqdVars = pcstdt pcsttm;
    %if Y eq %tu_isvarindsplan(dsetin=&prefix._dsplan,var=&thisVar,attribmvar=varAttrib) %then
    %do;
      attrib &thisVar &varAttrib;
      %let missingVars = %tu_chkvarsexist(&currentDataset,&reqdVars);
      %if %length(&missingVars) gt 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: Cannot derive &thisVar (as required by Dataset Plan) because source variables are missing: &missingVars;
        call symput('G_ABORT','1');
      %end;
      %else
      %do;
        &thisVar = &derivation;
      %end;
    %end;
    %else
    %do;
      %if &g_debug ge 1 %then
        %put RTD%str(EBUG): &sysmacroname: Will not derive &thisVar (not in Dataset Plan);
    %end;

    /* PCENDM Created from PCENDT and PCENTM */
    %let thisVar = PCENDM;
    %let derivation = dhms(pcendt,hour(pcentm)
                          ,minute(pcentm)
                          ,second(pcentm)
                          );
    %let reqdVars = pcendt pcentm;
    %if Y eq %tu_isvarindsplan(dsetin=&prefix._dsplan,var=&thisVar,attribmvar=varAttrib) %then
    %do;
      attrib &thisVar &varAttrib;
      %let missingVars = %tu_chkvarsexist(&currentDataset,&reqdVars);
      %if %length(&missingVars) gt 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: Cannot derive &thisVar (as required by Dataset Plan) because source variables are missing: &missingVars;
        call symput('G_ABORT','1');
      %end;
      %else
      %do;
        &thisVar = &derivation;
      %end;
    %end;
    %else
    %do;
      %if &g_debug ge 1 %then
        %put RTD%str(EBUG): &sysmacroname: Will not derive &thisVar (not in Dataset Plan);
    %end;

    /* PCLLQN Derive from PCLLQC */
    %let thisVar = PCLLQN;
    %let derivation = input(PCLLQC,??BEST.);
    %let reqdVars = PCLLQC;
    %if Y eq %tu_isvarindsplan(dsetin=&prefix._dsplan,var=&thisVar,attribmvar=varAttrib) %then
    %do;
      attrib &thisVar &varAttrib;
      %let missingVars = %tu_chkvarsexist(&currentDataset,&reqdVars);
      %if %length(&missingVars) gt 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: Cannot derive &thisVar (as required by Dataset Plan) because source variables are missing: &missingVars;
        call symput('G_ABORT','1');
      %end;
      %else
      %do;
        &thisVar = &derivation;
      %end;
    %end;
    %else
    %do;
      %if &g_debug ge 1 %then
        %put RTD%str(EBUG): &sysmacroname: Will not derive &thisVar (not in Dataset Plan);
    %end;

    /* PCNUMCOM Set to blank */
    %let thisVar = PCNUMCOM;
    %let derivation = "";
    %if Y eq %tu_isvarindsplan(dsetin=&prefix._dsplan,var=&thisVar,attribmvar=varAttrib) %then
    %do;
      attrib &thisVar &varAttrib;
      &thisVar = &derivation;
    %end;
    %else
    %do;
      %if &g_debug ge 1 %then
        %put RTD%str(EBUG): &sysmacroname: Will not derive &thisVar (not in Dataset Plan);
    %end;

    /* PCPROX Initially set to "N" by Arpk, then set by tc_wnlexcl */
    %let thisVar = PCPROX;
    %let derivation = "N";
    %if Y eq %tu_isvarindsplan(dsetin=&prefix._dsplan,var=&thisVar,attribmvar=varAttrib) %then
    %do;
      attrib &thisVar &varAttrib;
      &thisVar = &derivation;
    %end;
    %else
    %do;
      %if &g_debug ge 1 %then
        %put RTD%str(EBUG): &sysmacroname: Will not derive &thisVar (not in Dataset Plan);
    %end;

    /*
    / PCPTMEN Derive from PTM.  
    / Used with Urine data (upcase(pctyp) eq 'URINE').   
    / If not urine data pcptmen missing.
    / If URINE data then PTM will be of following form  
    / #h-#h  or #hrs-#hrs.  Select 2nd time point.  End time point.   
    / For example if PTM EQ '0h-12h' then pcptmen=12
    /------------------------------------------------------*/
    %let thisVar = PCPTMEN;
    %let reqdVars = PCTYP PTM;
    %if Y eq %tu_isvarindsplan(dsetin=&prefix._dsplan,var=&thisVar,attribmvar=varAttrib) %then
    %do;  /* Var is in plan */
      attrib &thisVar &varAttrib;
      %let missingVars = %tu_chkvarsexist(&currentDataset,&reqdVars);
      %if %length(&missingVars) gt 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: Cannot derive &thisVar (as required by Dataset Plan) because source variables are missing: &missingVars;
        call symput('G_ABORT','1');
      %end;
      %else
      %do;  /* No missing vars */
        if upcase(pctyp) ne 'URINE' then
        do;
          PCPTMEN = .;
        end;
        else
        do;  /* pctyp=urine */
          /*AR4*/
          length pcptmen_c $20;
          drop w2 rw2 pcptmen_c;
          w2=upcase(scan(ptm,2,'-'));
          if w2 eq '' /* WJB1 */ and index(upcase(compress(ptm,'-')),'PREDOSE')=0 /* WJB1 */ then
          do;
            put "RTE" "RROR: &sysmacroname: Invalid PTM data: No hyphen or no second value: " ptm=;
            call symput('G_ABORT','1');
            pcptmen_c='';
            pcptmen=.;
          end;
          else
          do;
            rw2 = left(reverse(w2));
            select;
              when ('H' eq: rw2) pcptmen_c=substr(w2,1,length(w2)-1);
              when ('SRH' eq: rw2) pcptmen_c=substr(w2,1,length(w2)-3);
              otherwise
              do;
                if index(upcase(compress(ptm,'-')),'PREDOSE')=0 then do; /* WJB1 */
                  put "RTE" "RROR: &sysmacroname: Invalid PTM data: No valid time unit for second value: " ptm=;
                  call symput('G_ABORT','1');
                  pcptmen_c='';
                  pcptmen=.;
                end;
              end;
            end;
            if pcptmen_c ne '' then
            do;
              pcptmen = input(pcptmen_c,??best.);
              if pcptmen eq . then
              do;
                put "RTE" "RROR: &sysmacroname: Invalid PTM data: Second value is not numeric: " ptm=;
                call symput('G_ABORT','1');
              end;
            end;
          end;

        end; /* pctyp=urine */
      %end; /* No missing vars */
    %end; /* Var is in plan */
    %else
    %do;
      %if &g_debug ge 1 %then
        %put RTD%str(EBUG): &sysmacroname: Will not derive &thisVar (not in Dataset Plan);
    %end;
  run;
  %tu_abort;

  %let currentDataset=&prefix._11;

  /* Start new data step so macros resolve in correct order */ /* ATM1 */
  data &prefix._12;
    set &currentDataset;

    /* PCENTMDV Derived: PCATMEN - PCPTMEN */
    %let thisVar = PCENTMDV;
    %let derivation = PCATMEN - PCPTMEN;
    %let reqdVars = PCATMEN PCPTMEN;
    %if Y eq %tu_isvarindsplan(dsetin=&prefix._dsplan,var=&thisVar,attribmvar=varAttrib) %then
    %do;
      attrib &thisVar &varAttrib;
      %let missingVars = %tu_chkvarsexist(&currentDataset,&reqdVars);
      %if %length(&missingVars) gt 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: Cannot derive &thisVar (as required by Dataset Plan) because source variables are missing: &missingVars;
        call symput('G_ABORT','1');
      %end;
      %else
      %do;
        &thisVar = &derivation;
      %end;
    %end;
    %else
    %do;
      %if &g_debug ge 1 %then
        %put RTD%str(EBUG): &sysmacroname: Will not derive &thisVar (not in Dataset Plan);
    %end;

    /* PCSTTMDV Derived from PCATMNUM - ELTMSTN */ /*AR6*/
    %let thisVar = PCSTTMDV;
    %let derivation = PCATMNUM - ELTMSTN;
    %let reqdVars = PCATMNUM ELTMSTN;
        
    /* Check if ELTMSTN is consistent with midpoint of PTM, if not warn user */ /* WJB1 */
    %if %length(%tu_chkvarsexist(&currentDataset,&reqdVars)) ne 0 %then
    %do; 
      /* AJC001: Remove erroneous semi-colon in message */
      %put RTE%str(RROR): &sysmacroname: PCSTTMDV will not be derived due to &reqdVars not being present in the data;
      %let g_abort = 1;
    %end;
    %else %do;
      drop _pcptmst _pcptmen;
      _pcptmst  = input(scan(ptm,1,' -H'),??best.); /* Derive start hour of PTM (as temporary var) */ /* WJB1 */
      _pcptmen = input(upcase(scan(scan(ptm,2,'-'),1,' -H')),??best.); /* Derive end hour of PTM (as temporary var) */ /* WJB1 */
      if _pcptmen ne . and _pcptmst ne . and ((_pcptmen+_pcptmst)/2)-eltmstn ne 0 then do;  /* Check if ELTMSTN is midpoint of PTM */ /* WJB1 */
        put "RTW" "ARNING: &sysmacroname: " ELTMNUM=  ELTMUNIT "for urine data is not the midpoint of " PTM= ;
        put "RTW" "ARNING: &sysmacroname: PCSTTMDV will not be calculated correctly.";
      end; /* Check if ELTMSTN is consistent with midpoint of PTM */
        
      /* Derive variable */
      &thisVar = &derivation;
    %end;
    
    /* PCTMDVU Set to HRS and make sure that associated values are in decimal hours */
    %let thisVar = PCTMDVU;
    %let derivation = "%qupcase(&dvtmstdunit)";  
    &thisVar = &derivation;

    /* PCVOLU Hard-coded as "mL" for IDSL studies */
    %let thisVar = PCVOLU;
    %let derivation = "mL";
    %if (("&g_datatype"="IDSL") and (Y eq %tu_isvarindsplan(dsetin=&prefix._dsplan,var=&thisVar,attribmvar=varAttrib))) %then
    %do;
      attrib &thisVar &varAttrib;
      &thisVar = &derivation;
    %end;
    %else
    %do;
      %if &g_debug ge 1 %then
        %put RTD%str(EBUG): &sysmacroname: Will not derive &thisVar (not in Dataset Plan);
    %end;

    /* PCSTRESN If pcorres is number set pcstresn=pcorres otherwise pcstresn=missing */
    %let thisVar = PCSTRESN;
    %let derivation = input(PCORRES,??BEST.);
    %let reqdVars = PCORRES;
    %if &g_datatype eq IDSL %then %do;	     /* WJB2 */
      %let varFound = %tu_isvarindsplan(dsetin=&prefix._dsplan,var=&thisVar,attribmvar=varAttrib);
    %end;
    %else %do;
      %if %sysfunc(indexw(&adamparmvals,&thisVar)) %then %let varFound = Y;
      %else %let varfound = N;
    %end;  
    %if &varFound eq Y %then %do;
      %if &g_datatype eq IDSL %then attrib &thisVar &varAttrib;;        /* WJB2 */
      %let missingVars = %tu_chkvarsexist(&currentDataset,&reqdVars);
      %if %length(&missingVars) gt 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: Cannot derive &thisVar (as required by Dataset Plan) because source variables are missing: &missingVars;
        call symput('G_ABORT','1');
      %end;
      %else
      %do;
        &thisVar = &derivation;
      %end;
    %end;
    %else
    %do;
      %if &g_debug ge 1 %then
        %put RTD%str(EBUG): &sysmacroname: Will not derive &thisVar (not in Dataset Plan);
    %end;
    
    /* PCSTRESC Set to PCORRES (though DSM currently says "Derive from PCSTRESN") */
    %let thisVar = PCSTRESC;
    %let derivation = PCORRES;
    %let reqdVars = PCORRES;
    %if &g_datatype eq IDSL %then %do;		   /* WJB2 */
      %let varFound = %tu_isvarindsplan(dsetin=&prefix._dsplan,var=&thisVar,attribmvar=varAttrib);
    %end;
    %else %do;
      %if %sysfunc(indexw(&adamparmvals,&thisVar)) %then %let varFound = Y;
      %else %let varfound = N;
    %end;  
    %if &varFound eq Y %then %do;
      %if &g_datatype eq IDSL %then attrib &thisVar &varAttrib;;         /* WJB2 */
      %let missingVars = %tu_chkvarsexist(&currentDataset,&reqdVars);
      %if %length(&missingVars) gt 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: Cannot derive &thisVar (as required by Dataset Plan) because source variables are missing: &missingVars;
        call symput('G_ABORT','1');
      %end;
      %else
      %do;
        &thisVar = &derivation;
      %end;
    %end;
    %else
    %do;
      %if &g_debug ge 1 %then
        %put RTD%str(EBUG): &sysmacroname: Will not derive &thisVar (not in Dataset Plan);
    %end;

    /*
    / PCSTRESU Set to PCORRESU because no stdunits done. 
    / (we must assume it was not done in sms2k)
    /------------------------------------------------------*/
    %let thisVar = PCSTRESU;
    %let derivation = PCORRESU;
    %let reqdVars = PCORRESU;
    %if &g_datatype eq IDSL %then %do;	    /* WJB2 */
      %let varFound = %tu_isvarindsplan(dsetin=&prefix._dsplan,var=&thisVar,attribmvar=varAttrib);
    %end;
    %else %do;
      %if %sysfunc(indexw(&adamparmvals,&thisVar)) %then %let varFound = Y;
      %else %let varfound = N;
    %end;  
    %if &varFound eq Y %then %do;
      %if &g_datatype eq IDSL %then attrib &thisVar &varAttrib;;      /* WJB2 */
      %let missingVars = %tu_chkvarsexist(&currentDataset,&reqdVars);
      %if %length(&missingVars) gt 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: Cannot derive &thisVar (as required by Dataset Plan) because source variables are missing: &missingVars;
        call symput('G_ABORT','1');
      %end;
      %else
      %do;
        &thisVar = &derivation;
      %end;
    %end;
    %else
    %do;
      %if &g_debug ge 1 %then
        %put RTD%str(EBUG): &sysmacroname: Will not derive &thisVar (not in Dataset Plan);
    %end;

  run;
  %tu_abort;

  %let currentDataset=&prefix._12;

  /* Start new data step so macros resolve in correct order */ /* ATM1 */

  data &prefix._13;
    set &currentDataset;

    /*
    / PCUAE 
    / For Urine data
    / 1st check if denom of PCORRESU is ml.  If so proceed with calculation.  
    / If not apply the appropriate conversion to result.   
    / programmer will derive conversion.
    / PCUAE=PCSTRESN*PCVOL
    / otherwise missing
    /------------------------------------------------------*/
    %let thisVar = PCUAE;
    %let reqdVars = PCTYP PCORRESU PCSTRESN PCVOL;
    %if (("&g_datatype"="IDSL" and Y eq %tu_isvarindsplan(dsetin=&prefix._dsplan,var=&thisVar,attribmvar=varAttrib))  or ("&g_datatype"="CDISC" and %index(%upcase(&adamparmvals),PCUAE) gt 0)) %then
    %do;  /* Var is in plan */  /* ATM1 */
      %if ("&g_datatype"="IDSL") %then %do; attrib &thisVar &varAttrib; %end;
      %else %do; attrib PCUAE label='Urine Amount Excreted';  %end;
      /* No missing vars */
      /* AJC001: Prevent un(initialised) variable messages */
      %if &g_datatype eq IDSL %then
      %do;
        if upcase(pctyp) ne 'URINE' then
        do;
      %end;
      %else
      %do;
        if upcase(pcspec) ne 'URINE' or (upcase(pcspec) eq 'URINE' and upcase(pctestcd) in ("PKSMPPH" "PKSMPVOL" "PKSMPWT")) then
        do; /* AJC002: Ignore sample volume, weight and pH records for CDISC studies */
      %end;
          pcuae = .;
        end;
      /* AJC001: Check required variables are present for PCUAE derivation */
      %if %length(%tu_chkvarsexist(&currentDataset,PCORRESU PCSTRESN PCVOL PCVOLU)) eq 0 %then
      %do;
        else
        do;
          if upcase(scan(PCORRESU,2,'/')) eq "ML" and upcase(pcvolu)='ML' then
          do;
            PCUAE=PCSTRESN*PCVOL;
          end;
          else
          do;
            %tu_byid(dsetin=&currentDataset
                    ,invars=&g_subjid visit visitnum pcorresu
                    ,outvar=__msg
                    );
            put "RTW" "ARNING: &sysmacroname: Denominator of results units is not 'ml': " __msg;
          end;
        end;
        drop __msg;
      %end;
      /* No missing vars */
    %end; /* Var is in plan */
    %else
    %do;
      %if &g_debug ge 1 %then
        %put RTD%str(EBUG): &sysmacroname: Will not derive &thisVar (not in Dataset Plan);
    %end;

    /*
    / PCCOM Derive from, PCORRES
    / Contains any non-numeric results and sample comments 
    /   collected with the results (such as NQ, NS etc).
    / If entry is not numeric captue text part here
    / Ex if PCORRES EQ 123.4 then PCCOM=' '
    / IF PCORRES EQ 'NQ' then PCCOM='NQ'
    / IF PCORRES EQ 'IS' then PCCOM='IS'
    /------------------------------------------------------*/
    %let thisVar = PCCOM;
    %let reqdVars = PCORRES;
    %if &g_datatype eq IDSL %then %do;	        /* WJB2 */
      %let varFound = %tu_isvarindsplan(dsetin=&prefix._dsplan,var=&thisVar,attribmvar=varAttrib);
    %end;
    %else %do;
      %if %sysfunc(indexw(&adamparmvals,&thisVar)) %then %let varFound = Y;
      %else %let varfound = N;
    %end;  
    %if &varFound eq Y %then %do;
      %if &g_datatype eq IDSL %then attrib &thisVar &varAttrib;;         /* WJB2 */
      %let missingVars = %tu_chkvarsexist(&currentDataset,&reqdVars);
      %if %length(&missingVars) gt 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: Cannot derive &thisVar (as required by Dataset Plan) because source variables are missing: &missingVars;
        call symput('G_ABORT','1');
      %end;
      %else
      %do;
        if input(pcorres,??best.) eq . then
          pccom = pcorres;
      %end;
    %end;
    %else
    %do;
      %if &g_debug ge 1 %then
        %put RTD%str(EBUG): &sysmacroname: Will not derive &thisVar (not in Dataset Plan);
    %end;
   
    
  run;    
  %tu_abort;
  %let currentDataset = &prefix._13;

  %if &g_debug ge 1 %then
  %do;
    title "RTD" "EBUG: &sysmacroname: Output dataset (&currentDataset) "
          'from 1st derivations';
    proc contents data=&currentDataset;
    run;
  %end;
  %if &g_debug ge 2 %then
  %do;
    title "RTD" "EBUG: &sysmacroname: Output dataset (&currentDataset, &__debug_obs) "
          'from 1st derivations';
    proc print data=&currentDataset (&__debug_obs);
    run;
  %end;

  /* 7. Recreate ELTMSTN to units specified in ELTMSTDUNIT      
  /     and PCDUR, PCPTMEN, PCSTTMDV and PCENTMDV to units specified in DVTMSTDUNIT,  
  /     and set ELTMSTU = ELTMSTDUNIT and PCDURU and PCTMDVU = DVTMSTDUNIT 
  /-------------------------------------------------------------------------------- */ /* WJB1 */
  %if ("&g_datatype"="IDSL") %then %do;  /* ATM1 */
  data &prefix._14;
    set &currentDataset;

    /* Recreate ELTMSTN in units specified in ELTMSTDUNIT */
    eltmstu = "&eltmStdUnit";
    select (eltmunit);
      when ('DAY')
      do;  /* day */
        %if &eltmStdUnit eq SEC %then %str(eltmstn = eltmnum * 86400;);
        %else %if &eltmStdUnit eq MIN %then %str(eltmstn = eltmnum * 1440;);
        %else %if &eltmStdUnit eq HRS %then %str(eltmstn = eltmnum * 24;);
        %else %if &eltmStdUnit eq DAY %then %str(eltmstn = eltmnum;);
      end; /* day */
      when ('HRS')
      do;  /* hrs */
        %if &eltmStdUnit eq SEC %then %str(eltmstn = eltmnum * 3600;);
        %else %if &eltmStdUnit eq MIN %then %str(eltmstn = eltmnum * 60;);
        %else %if &eltmStdUnit eq HRS %then %str(eltmstn = eltmnum;);
        %else %if &eltmStdUnit eq DAY %then %str(eltmstn = eltmnum / 24;);
      end; /* hrs */
      when ('MIN')
      do;  /* min */
        %if &eltmStdUnit eq SEC %then %str(eltmstn = eltmnum * 60;);
        %else %if &eltmStdUnit eq MIN %then %str(eltmstn = eltmnum;);
        %else %if &eltmStdUnit eq HRS %then %str(eltmstn = eltmnum / 60;);
        %else %if &eltmStdUnit eq DAY %then %str(eltmstn = eltmnum / 1440;);
      end; /* min */
      when ('SEC')
      do;  /* sec */
        %if &eltmStdUnit eq SEC %then %str(eltmstn = eltmnum;);
        %else %if &eltmStdUnit eq MIN %then %str(eltmstn = eltmnum / 60;);
        %else %if &eltmStdUnit eq HRS %then %str(eltmstn = eltmnum / 3600;);
        %else %if &eltmStdUnit eq DAY %then %str(eltmstn = eltmnum / 86400;);
      end; /* sec */
      otherwise
        do;
          /* Message already passed to tu_byid during datastep &prefix._eltmst - no action taken here */ /* WJB1 */
        end;
      end;
    
      /* Modify derived durations to be in units specified in DVTMSTDUNIT */ /* WJB1 */
      %if       %qupcase(&dvtmstdunit) eq SEC %then %let derivation = * 3600;
      %else %if %qupcase(&dvtmstdunit) eq MIN %then %let derivation = * 60;
      %else %if %qupcase(&dvtmstdunit) eq DAY %then %let derivation = / 24;
      %else                                         %let derivation =;
      PCDUR    = PCDUR    &derivation; 
      PCPTMEN  = PCPTMEN  &derivation; 
      PCSTTMDV = PCSTTMDV &derivation; 
      PCENTMDV = PCENTMDV &derivation;     
  run;
  %let currentDataset = &prefix._14;

%end;

  /* 
  / 8. Perform imputations for : PCSTIMPN, PCRESIMP, PCWNLN, PCSTIMSN
  /    [WJB5671.01-010]  WJB1
  /    Perform flagging as appropriate 
  /      0 = Leading NQ                                                                                      
  /      1 = 1st phase measurable conc                                                                       
  /      2 = Mid-profile NQ  (>1 consecutive NQ where measurable concentrations exist before and after)      
  /      3 = 2nd+ phase measurable conc  (measurable conc which comes after mid-profile NQ)                  
  /      4 = Trailing NQ                                                                                     
  /      5 = Single mid-profile NQ                                                                           
  /      6 = Any non-numeric value other than NQ                                                             
  /      7 = Urine PK records (standard imputations do not apply)                                            
  /--------------------------------------------------------------------------------------------------  */ 

  %local planPCSTIMPN attrPCSTIMPN;
  %local planPCSTIMSN attrPCSTIMSN;
  %local planPCRESIMP attrPCRESIMP;
  %local planPCWNLN   attrPCWNLN;
  %local desccols incpcallcol;    /* WJB1 */

  %if &g_datatype eq IDSL %then %do;
    %let planPCSTIMPN = %tu_isvarindsplan(dsetin=&prefix._dsplan,var=PCSTIMPN,attribMvar=attrPCSTIMPN);
    %let planPCSTIMSN = %tu_isvarindsplan(dsetin=&prefix._dsplan,var=PCSTIMSN,attribMvar=attrPCSTIMSN);
    %let planPCRESIMP = %tu_isvarindsplan(dsetin=&prefix._dsplan,var=PCRESIMP,attribMvar=attrPCRESIMP);
    %let planPCWNLN = %tu_isvarindsplan(dsetin=&prefix._dsplan,var=PCWNLN,attribMvar=attrPCWNLN);
  %end;
  %else %do;
    %if %sysfunc(indexw(&adamparmvals,PCSTIMPN)) %then %let planPCSTIMPN = Y;
    %if %sysfunc(indexw(&adamparmvals,PCSTIMSN)) %then %let planPCSTIMSN = Y;
    %if %sysfunc(indexw(&adamparmvals,PCRESIMP)) %then %let planPCRESIMP = Y;
    %if %sysfunc(indexw(&adamparmvals,PCWNLN)) %then %let planPCWNLN = Y;
  %end;  

  %if &planPCWNLN eq Y or &planPCSTIMPN eq Y or &planPCSTIMSN eq Y or &planPCRESIMP eq Y %then  /*AR8*/
  %do;  /* Need to perform imputation */

    %if %tu_nobs(&currentDataset) lt 2 %then
    %do;
      %put RTE%str(RROR): &sysmacroname: Insufficient rows to perform imputations (must have at least 2);
      %tu_abort(option=force);
    %end;

    %let thisVar = PCSTIMPN/PCSTIMSN/PCRESIMP/PCWNLN;  /*AR8*/
    %let reqdVars = PCORRES PCSTRESN;  /* WJB2 */
    %let missingVars = %tu_chkvarsexist(&currentDataset,&reqdVars);
    %if %length(&missingVars) gt 0 %then
    %do;
      %put RTE%str(RROR): &sysmacroname: Cannot derive &thisVar (as required by Dataset Plan) because source variables are missing: &missingVars;
      %tu_abort(option=force);
    %end;

  /* Separate check for PCWNLN if urine records are present */   /* WJB1 */
    %let thisVar = PCWNLN;
    %let reqdVars = PCUAE PCDUR;
    %let missingVars = %tu_chkvarsexist(&currentDataset,&reqdVars);
    %if "&incurine"="Y" and %length(&missingVars) gt 0 %then
    %do;
      %put RTE%str(RROR): &sysmacroname: Cannot derive &thisVar (as required by Dataset Plan) for urine PK, because ;
      %put RTE%str(RROR): &sysmacroname: source variables have not been derived: &missingVars.;
      %tu_abort(option=force);
    %end;

  /* Establish if PCALLCOL is present in dataset */   /* WJB1 */
    %let incpcallcol=N;
    %let missingVars = %tu_chkvarsexist(&currentDataset,PCALLCOL);
    %if %length(&missingVars) eq 0 %then %do;  /* WJB2 */
      %let incpcallcol=Y;
    %end;

  /* Establish which BY vars exist */   /*AR5*/
    %local allcols foundcols;
    %let allcols=%upcase(&imputeby); /*AR6*/ /*AR7*/
    /* Create foundcols by removing chkvarsexist results from allcols */ /*AR7*/
    %local removeCols ptr word;
    %let removeCols=%tu_chkvarsexist(&currentdataset,&allcols);

    %let foundCols=;

    %do ptr=1 %to %tu_words(&allcols);
      %let word = %scan(&allcols,&ptr);
      %if not %sysfunc(indexw(&removeCols,&word)) %then
        %let foundCols = &foundCols &word;
    %end;

    %if %tu_words(&foundcols) lt 2 %then  /*AR8*/
    %do;
      %put RTE%str(RROR): &sysmacroname: Less than two variables in IMPUTEBY (&imputeby) exist in the concentration dataset;
      %tu_abort(option=force);
    %end;

    %let penulCol = %scan(&foundCols,-2);
    %if &g_debug ge 1 %then
      %put RTD%str(EBUG): &sysmacroname: ALLCOLS=&allcols, FOUNDCOLS=&foundcols, PENULCOL=&penulcol;

  /* Create desccols - version of foundcols each var prefixed with descending keyword, to allow reverse sorting */ /* WJB1 */
    %local desccols;
    data _null_;
      length desccols $200;
      n = 1;
      do until (scan("&foundcols",n-1)=scan("&foundcols",-1));
        dimp=compbl('descending '||scan("&foundcols",n)||' ');
        desccols=compbl(desccols)||compbl(dimp);
        n=n+1;
      end;
      call symput('desccols',desccols);
    run;

  /* Sort the dataset, flag unknown results (e.g. NA, NR, IS etc), and urine PK records,
  /  and sort them to the bottom of the dataset                               
  /------------------------------------------------------------------------------------ */ /* WJB1 */
    proc sort data=&currentDataset out=&prefix._imp10;
      by &foundcols;
    run;

    data &prefix._imp15;
      set &prefix._imp10;
      if upcase(pcspec) eq "URINE" then impflag=7;                         /* WJB2 */
      else if pcorres='NQ' or input(pcorres,??best.) ne . then impflag=.;
      else impflag=6;
      proc sort; 
        by impflag &foundcols;
    run;
  
  /* Merge dataset together with itself, incremented by one obs, to create next 
  /  result (resNext) variable                                         
  /----------------------------------------------------------------------------------- */ /* WJB1 */
    data &prefix._imp20;
      merge &prefix._imp15 (firstobs=1)
            &prefix._imp15 (firstobs=2 keep=pcorres rename=(pcorres=resNext));
      proc sort; 
        by impflag &imputeby;
    run;

    data &prefix._imp25 (drop=impflag2 resNext prevKnown);
      set &prefix._imp20;
      by impflag &foundcols;
      retain impflag2 prevKnown;

  /* Primary flagging    */ /* WJB1 */
      if impflag<6 then do;
        if impflag2 gt .z and impflag=. then impflag=impflag2;
        if first.&penulCol then impflag=0;                                    /* reset flagging */
        if impflag=0 and pcorres ne 'NQ' then impflag=1;        /* first measurable concentration */
        if impflag=5 then impflag=prevKnown;     /* retrieve last known value of impflag if req */
        if impflag in (1 3) and pcorres='NQ' and resNext eq 'NQ' then impflag=2;     /* >1 mid-profile NQ */  /* WJB2 */
        if impflag in (1 3) and pcorres='NQ' and resNext ne 'NQ' then do;/* single mid-profile NQ */
          prevKnown=impflag;
          impflag=5;
        end;
        if impflag=2 and pcorres ne 'NQ' then impflag=3;           /* 2nd+ phase measurable conc  */
        impflag2=impflag;
      end;
    run;

  /* Flag trailing NQs  */ /* WJB1 */

   /* Sort in reverse order         */
    proc sort data=&prefix._imp25 out=&prefix._imp30;
      by &desccols;
    run;

    data &prefix._imp35 (drop=endflag);
      set &prefix._imp30;
      by &desccols;
      retain endflag;
      if impflag<7 then do;  /* WJB2 */
        if first.&penulCol then endflag=0;                                     /* restart endflag */
        if impflag>0 and endflag=0 and pcorres='NQ' then impflag=4;        /* flag as trailing NQ */
        if input(pcorres,??best.) ne . then endflag=1;                 /* If measurable value, set endflag to 1 */ /* WJB2 */
      end;  
      proc sort; 
        by &foundcols;                                  /* Re-sort in imputation order */
    run;

   /* Set actual values  */ /* WJB1 */
    data &prefix._imp40 (drop=impflag);

      %if &g_datatype eq IDSL %then %do;   /* WJB2 */
        %if &planPCSTIMPN eq Y %then %do;
          attrib PCSTIMPN &attrPCSTIMPN; 
        %end;
        %else %do;
          drop PCSTIMPN; 
        %end;
        %if &planPCSTIMSN eq Y %then %do;
          attrib PCSTIMSN &attrPCSTIMSN; 
        %end;
        %else %do;
          drop PCSTIMSN; 
        %end;
        %if &planPCRESIMP eq Y %then %do;
          attrib PCRESIMP &attrPCRESIMP; 
        %end;
        %else %do;
          drop PCRESIMP; 
        %end;
        %if &planPCWNLN eq Y %then %do;
          attrib PCWNLN &attrPCWNLN; 
        %end;
        %else %do;
          drop PCWNLN; 
        %end;
      %end;

      set &prefix._imp35;
      pcresimp='N';
      pcwnlu=pcorresu;
      if impflag=0 then do;                                               /* Leading NQs   */
        pcstimpn=0;
        pcstimsn=0;
        pcwnln=0;
        pcresimp='Y';
      end;
      else if impflag=1 or (impflag=3 and "&imputetype"="A") then do;     /* Measurable concentrations */
        pcstimpn=pcstresn;
        pcstimsn=pcstresn;
        pcwnln=pcstresn;
      end;
      else if impflag=2 then do;                                          /* Mid-profile NQs */
        if "&imputetype"="S" then do;
          pcstimpn=0;
          pcstimsn=0;
        end;
        else if "&imputetype"="A" then do;
          pcstimpn=PCLLQN/2;
          pcstimsn=PCLLQN/2;
          pcwnln=PCLLQN/2;
        end;
        pcresimp='Y';
      end;
      else if impflag=3 and "&imputetype"="S" then do;                    /* 2nd+ phase measurable concs   */
        pcstimsn=pcstresn;
        put "RTW" "ARNING: TU_PKCNCDERV: Imputation has dropped PCWNLN concentration for " PCSPEC= ", " &g_subjid= ", " VISIT= ", " PTM=;      /* WJB2 */
        put "RTW" "ARNING: TU_PKCNCDERV: Use of alternative imputation may be appropriate.";
      end;
      else if impflag=4 then do;                                          /* Trailing NQs   */
        pcstimpn=0;
        pcresimp='Y';
      end;
      else if impflag=7 then do;                         /* Urine */  /* WJB2 */
        /* AJC001: Modified to prevent un(initialised) variable messages */
        if %if &incpcallcol eq Y %then pcallcol ne "N" and; eltmnum > 0 then do;
          if pcstresn ne . then do;  
            pcstimpn=pcstresn;
            pcstimsn=pcstresn;
            pcuer=pcuae/pcdur;
            pcwnln=pcuer;
          end;
          else if pcorres='NQ' then do;
            pcuer=0;
            pcwnln=0;
          end;
        end;
        if pcorresu ne "" then pcwnlu = scan(pcorresu,1,"/") || "/" || lowcase(tranwrd(tranwrd("%qupcase(&dvtmstdunit)","HRS","hr"),"SEC","s")); /* WJB2 */
      end;
    run;

    %let currentDataset = &prefix._imp40;

    %if &g_debug ge 1 %then
    %do;
      title "RTD" "EBUG: &sysmacroname: Output dataset (&currentDataset) "
            'from concentration imputation';
      proc contents data=&currentDataset;
      run;
    %end;
    %if &g_debug ge 2 %then
    %do;
      title "RTD" "EBUG: &sysmacroname: Output dataset (&currentDataset, &__debug_obs) "
            'from concentration imputation';
      proc print data=&currentDataset (&__debug_obs);
      run;
    %end;

  %end;

  /* 9. Create output dataset */
  
  data &dsetout;
    set &currentDataset;
  run;

  /* 10. Remove any temporary datasets (%tu_tidyup) */
  %tu_tidyup(rmdset=&prefix:
            ,glbmac=NONE
            );
  quit;

  /* 11. Call %tu_abort() */
  %tu_abort;

%mend tu_pkcncderv;   
