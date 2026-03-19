/*******************************************************************************
|
| Macro Name:      tu_derive
|
| Macro Version:   5
|
| SAS Version:     9
|
| Created By:      Mark Luff/Eric Simms
|
| Date:            07-Jun-2004
|
| Macro Purpose:   Dataset specific derivations
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME               DESCRIPTION                                        DEFAULT
| -----------------  -------------------------------------------------  ----------
| DSETIN              Specifies the dataset for which the derivations   (None)            
|                     are to be done.                                                     
|                     Valid values: valid dataset name                                    
|                                                                                         
| DSETOUT             Specifies the name of the output dataset to be    (None)            
|                     created.                                                            
|                     Valid values: valid dataset name                                    
|                                                                                         
| DEMODSET            Specifies an SI-format DEMO dataset to use for    dmdata.demo       
|                     various derivations.                                                
|                                                                                         
| DOMAINCODE          This signifies the type of dataset passed in and  N                 
|                     therefore the derivations to be performed.                          
|                     Expected values are:                                                
|                     AE   adverse events                                                 
|                     BL   blind                                                          
|                     CM   conmeds                                                        
|                     CY   cycle                                                          
|                     DG   gskdrug                                                        
|                     DM   demo                                                           
|                     DS   disposit                                                       
|                     DS2  ds                                                       
|                     EG   ecg               
|                     EX   exposure                                                       
|                     GP   genpro                                                         
|                     IE   elig                                                           
|                     IP   ipdisc                                                           
|                     LB   lab                                                            
|                     LP   lbiopsy                                                           
|                     LI   limaging                                                           
|                     MD   meddra    
|                     MH   medhist                                
|                     MS   mstone                                                         
|                     PN   pop                                                            
|                     PR   period                                                         
|                     PT   prvtrial                                                       
|                     RU   rucam                                                       
|                     SD   stopdrug                                                       
|                     SF   scrnfail                                                       
|                     SP   surgery                                                        
|                     STG  stage                                                         
|                     SU   subuse                                                         
|                     TR   trt                                                            
|                     TS   timslc                                                         
|                     VS   vitals                                                         
|                     VT   visit                                                          
|                                                                                         
| DURATIONUNITS       Units to use for duration in EX and AE (EXPOSURE  Days              
|                     and AE) derivations. Valid Values:                                  
|                     Years, Months, Weeks, Days or Hours                                 
|                                                                                         
| EXPOSUREDSET        Specifies an SI-format EXPOSURE dataset to use    dmdata.exposure   
|                     for various derivations.                                            
|                                                                                         
| NODERIVEVARS        Lists the variables for which derivation is not   (None)            
|                     to be done.                                                         
|                                                                                         
| RANDALLDSET         Specifies an SI-format RANDALL dataset to use     dmdata.randall    
|                     for various derivations.                                            
|                     Note: This parameter is not used in current                         
|                     version. It should be passed to %tu_acttrt in                       
|                     future release.                                                     
|                                                                                         
| RANDDSET            Specifies an SI-format RAND dataset to use for    dmdata.rand       
|                     various derivations.                                                
|                                                                                         
| REFDATEDSETSUBSET   May be used regardless of the value of            (None)            
|                     REFDATEOPTION in order to better select the                         
|                     reference date.                                                     
|                                                                                         
| REFDATEOPTION       The reference date will be used in the            treat             
|                     calculation of the age values.                                      
|                                                                                         
|                     TREAT - Trt start date from                                         
|                     DMDATA.EXPOSURE                                                     
|                     VISIT - Visit date from                                             
|                     DMDATA.VISIT                                                        
|                     RAND  - Randomization date from                                     
|                     DMDATA.RAND                                                         
|                     OTHER  Date from the                                               
|                     REFDATESOURCEVAR                                                    
|                     variable on the                                                     
|                     REFDATESOURCEDSET                                                   
|                     dataset                                                             
|                                                                                         
| REFDATESOURCEDSET   Required if REFDATEOPTION is OTHER. Use the       (None)            
|                     variable REFDATESOURCEVAR from the                                  
|                     REFDATESOURCEDSET.                                                  
|                                                                                         
| REFDATESOURCEVAR    Required if REFDATEOPTION is OTHER. Use the       (None)            
|                     variable REFDATESOURCEVAR from the                                  
|                     REFDATESOURCEDSET.                                                  
|                                                                                         
| REFTIMESOURCEVAR    Required if REFDATEOPTION is OTHER. Use the       (None)            
|                     variable REFTIMESOURCEVAR from the                                  
|                     REFDATESOURCEDSET.                                                  
|                                                                                         
| REFDATEVISITNUM     Required if REFDATEOPTION is VISIT.               (None)            
|                                                                                         
| TMSLICEDSET         Specifies an SI-format TMSLICE dataset to use     dmdata.tmslice    
|                     for various derivations.                                            
|                                                                                         
| VISITDSET           Specifies an SI-format VISIT dataset to use for   dmdata.visit    
|                     various derivations.                                                
|                    
| XOVARSFORPGYN       Specifies whether to derive crossover stydy       N
|                     specific variables for parallel study                 
|                     
| -----------------  -------------------------------------  -------  ----------
|
| The macro references the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETIN            Req      Parameter specified dataset
| &DEMODSET          Opt      Parameter specified demography dataset
| &EXPOSURE          Opt      Parameter specified exposure dataset
| &RANDDSET          Opt      Parameter specified rand dataset
| &RANDALLDSET       Opt      Parameter specified randall dataset
| &TMSLICINGSET      Opt      Parameter specified time slicing dataset
| &VISITDSET         Opt      Parameter specified visit dataset
| -----------------  -------  -------------------------------------------------
|
| Output:
|
| The macro outputs the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETOUT           Req      Parameter specified dataset
| -----------------  -------  -------------------------------------------------
|
| Global macro variables created: NONE
|
|
| Macros called:
|(@) tr_putlocals
|(@) tu_abort
|(@) tu_acttrt
|(@) tu_chkvarsexist
|(@) tu_nobs
|(@) tu_perstd
|(@) tu_putglobals
|(@) tu_refdat
|(@) tu_tidyup
|(@) tu_visitdt
|
| Example:
|    %tu_derive(
|         dsetin            = _ae1,
|         dsetout           = _ae2,
|         domaincode        = AE,
|         noderivevars      = AEACTSDY,
|         refdateoption     = VISIT,
|         refdatevisitnum   = 20
|         );
|
|******************************************************************************
| Change Log
|
| Modified By:               Yongwei Wang
| Date of Modification:      18-Jan-2005
| New version/draft number:  1/2
| Modification ID:           YW001
| Reason For Modification:   1.Modified adding AEPTR1ST process
|                            2.Changed DMDATA.EXPOSURE in code to &EXPOSUREDSET
|                            3.Re-arranged the code so that the call of 
|                              %tu_refdat, %tu_visitdt and %tu_perstd can
|                              be in one place
|                            4.Put the calculation of duration in one place.
|                            5.Changed calculation of AEDUR, EXDUR
|                            6.Changed the call of %tu_perstd and %tu_acttrt
|                              so that the time variable can be used.
|                            7.Added more checks so that the RTERROR, in some
|                              cases, will not occured in the macros called by 
|                              this macro.
|                            8.Added parameter TMSLICEDSET, RANDALLDSET and
|                              VISITDSET
|                            9.Added deriviation of DMREFTIM and EXDURCUM
|                           10.Removed derivaton of SPD_, SPEND_ and SUSMLSD_
|                           11.Added the derivation of SUDT
|
| Modified By:              Yongwei Wang
| Date of Modification:     18-Feb-2005
| New version/draft number: 1/3
| Modification ID:          YW002
| Reason For Modification:  1. Changed AEDURU to one character
|                           2. Modified the calculation of AETRTST
|                           3. Dropped variables which should not be derived.
|
| Modified By:              Yongwei Wang
| Date of Modification:     01-Mar-2005
| New version/draft number: 1/4
| Modification ID:          YW003
| Reason For Modification:  Changed calculation of QTCB and QTCF because of the
|                           changes of IDSL.
|
| Modified By:              Yongwei Wang
| Date of Modification:     11-Mar-2005
| New version/draft number: 1/5
| Modification ID:          YW003
| Reason For Modification:  Removed derivation of RR, QTCF and QTCB.
|
| Modified By:              Yongwei Wang
| Date of Modification:     17-Mar-2005
| New version/draft number: 1/6
| Modification ID:          YW004
| Reason For Modification:  1.If LBAGE in &noderivevars, LBAGEWK, LBAGEMO and
|                             LBAGEDY are not derived. Get it fixed.
|                           2.If PERTSTDT less than AESTDT, set AEPTR1ST to 
|                             missing
|
| Modified By:              Yongwei Wang
| Date of Modification:     22-Apr-2005
| New version/draft number: 1/7
| Modification ID:          YW005
| Reason For Modification:  Changed 'le' to 'lt' in condition "(( a.aestdt le b._hi)
|                           or (( a.aestdt eq b._hi ) and ( a.aesttm le b._hitime )))",      
|                           when derive AETRTST. The condition added extra records.
|
| Modified By:              Yongwei Wang
| Date of Modification:     29-Sep-2005
| New version/draft number: 2/1
| Modification ID:          YW006
| Reason For Modification:  Requeseted by change request HRT0090
|                           1. Added new derive varialbe TPERDY and XPERDY for 
|                              domain BL, DS, EG, LB, SD, SU, SP and VS
|                           2. Added new derive variable TPERSDY XPERSDY TPERSDY
|                              TPEREDY for domain AE and CM
|                           3. The TPERDY/TPERSDY and XPERDY/XPERSDY is derived
|                              by calling %tu_perstd
|                           4. For AE, TPEREDY and XPEREDY is derived the same
|                              way as AEPEREDY
|                           5. For CM, TPEREDY and XPEREDY is derived the same
|                              way as CMPEREDY 
|                           6. Removed macro variable EXDSET, which is used to
|                              passed &EXPOSUREDSET to %tu_perstd for AE.   
|                            
| Modified By:              Yongwei Wang
| Date of Modification:     08-Oct-2005
| New version/draft number: 2/2
| Modification ID:          YW007
| Reason For Modification:  1. Added a condition when calculation XPEREDY, 
|                              according to the request of UAT team
|                           2. Changed PERSTDT to PERTSTDT in if statement 
|                              when calculating AEPTR1ST      
|
| Modified By:              Yongwei Wang
| Date of Modification:     22-Sep-2006
| New version/draft number: 3/1
| Modification ID:          YW008
| Reason For Modification:  1. To build TC_EGANAL macros (change request HRT0127), added derivation 
|                              of variable EGACTEDY EGPEREDY TPEREDY XPEREDY for domain EG.
|                           2. Added derive of EGAGE, EGAGEDY, EGAGEWK and EGAGEMO. 
|                           3. Added derive of VSAGE, VSAGEDY, VSAGEWK and VSAGEMO. 
|                           4. Added variable SPACTEDY SPPEREDY TPEREDY XPEREDY for domain SP
|                           5. Required by change request HRT0105:
|                              a. Changed %index to %sysfunc(indexw())
|                              b. Check if VISITNUM exists before calling %tu_visitdt
|                              c. Check if DMDT, VSDT, etc in &NODERIVEVARS variables before calling 
|                                 %tu_visitdt                           
|
| Modified By:              Yongwei Wang
| Date of Modification:     07-Jun-2007
| New version/draft number: 4/1
| Modification ID:          YW009
| Reason For Modification:  1. Added deriviation for domain IPDISC, DS, RUCAM, LBIOPSY and LIMAGING
|                           2. Removed RTWARNING message if VISITNUM does not exist when
|                              deriving DMDT/MHDT and DMACTDY/MHACTDY
|                           3. Fixed a bug of non-matching do-end loop when &DURATIIONUNIT=HOURS
|                           4. Removed RTWARNING message when NODERIVEVARS=AEPERSDY.
|                           5. For domaincode in AE, IP and SD, if EXENDT does not exist or it has
|                              no non-missing values in EXPOSUREDSET, use EXSTDT to replace EXENDT 
|                           6. Removed derivation of variable EGACTEDY EGPEREDY TPEREDY XPEREDY for 
|                              domain EG because of the change of IDSL standard
|                           7. Changed %sysfunc(exist()) to %tu_nobs to check if data set exist
|                           8. Transfered internal macro %getedy and %domainage to plain macro code.
|
| Modified By:              Yongwei Wang
| Date of Modification:     10-Oct-2007
| New version/draft number: 4/2
| Modification ID:          YW010
| Reason For Modification:  1. Added code to use SDIPCD as merging variable when deriving SDENDT.
|                           2. Derived RUDT based on VISITNUM, if it does not exist                              
|                           3. Derived SDENDY based on SDENDT for domaincode=IP (HRT0192)
|                           4. Derived ACTDY based on ACTDT for domaincode=IP. It used to be derived
|                              based on SDENDT.
|
| Modified By:              Yongwei Wang
| Date of Modification:     10-Oct-2007
| New version/draft number: 5/1
| Modification ID:          YW011
| Reason For Modification:  1. Passed VISITDSET to %tu_visitdt
|                           2. Passed EXPOSUREDSET, RANDDSET, VISITDSET to %tu_refdat,
|                           3. Passed VISITDSET AND EXPOSUREDSET to %tu_acttrt.
|
| Modified By:              Gail Knowlton	
| Date of Modification:     27-Oct-2008
| New version/draft number: 5/2
| Modification ID:          GK001
| Reason For Modification:  1. Added missing parenthesis to the calculation of duration
|                              when duration units = years 
|                           2. Repunctuated an RTError message 
|
| Modified By:              Barry Ashby
| Date of Modification:     8-Jan-2009
| New version/draft number: 5/3
| Modification ID:          BA001
| Reason For Modification:  1. If EXSTDT and EXENDT exist in the RUCAM SI dataset then 
|                              use them to derive the following variables using the standard 
|                              algorithms: RUSTRTPT, RUTRT1ST and RUTRTST. Otherwise use
|                              EXSTDT and EXENDT variables from the EXPOSURE SI dataset. (HRT0212)
|                           2. Add functionality to derive GENPRO variable GPSEQ. (HRT0213)
|                           3. Merge CYCLE variable into the IPDISC dataset from the EXPOSURE
|                              dataset unless its already exists in the IPDISC dataset. (HRT0214)
|                           4. Update AGE variable derivations when BIRHTDT does not exist or is
|                              missing then the DEMO AGE variables are used to derive AGE 
|                              variables for: VS LB and EG. (HRT0217)
|
| Modified By:              Barry Ashby
| Date of Modification:     11-Jun-2009
| New version/draft number: 5/4
| Modification ID:          BA002
| Reason For Modification:  Changed SPACTEDY references to SPENDY. (HRT0226)
***************************************************************************************************/

%macro tu_derive (
   DSETIN              =,                  /* Input dataset */  
   DSETOUT             =,                  /* Output dataset */

   DEMODSET            =dmdata.demo,       /* Name of DEMO dataset to use */     
   DOMAINCODE          =N,                 /* Type of dataset: AE, BL, etc. */
   DURATIONUNITS       =Days,              /* Units to use for duration */
   EXPOSUREDSET        =dmdata.exposure,   /* Name of EXPOSURE dataset to use */
   NODERIVEVARS        =,                  /* List of variables to not be derived */
   RANDALLDSET         =dmdata.randall,    /* Name of RANDALL dataset to use */
   RANDDSET            =dmdata.rand,       /* Name of RAND dataset to use */
   REFDATEDSETSUBSET   =,                  /* WHERE clause applied to source dataset */
   REFDATEOPTION       =treat,             /* Reference date source option */
   REFDATESOURCEDSET   =,                  /* Reference date source dataset */
   REFDATESOURCEVAR    =,                  /* Reference date source date variable */
   REFDATEVISITNUM     =,                  /* Specific visit number at which reference date is to be taken */
   REFTIMESOURCEVAR    =,                  /* Reference time source time variable */
   TMSLICEDSET         =dmdata.tmslice,    /* Name of TMSLICE dataset to use */
   VISITDSET           =dmdata.visit,      /* Name of VISIT dataset to use */
   XOVARSFORPGYN       =N                  /* If derive crossover stydy specific variables for parallel study */
   );

   /*
   / Echo parameter values and global macro variables to the log.
   /----------------------------------------------------------------------------*/

   %local MacroVersion;
   %let MacroVersion = 5;
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals()

   %local prefix i vsdtvar perstdt timevar datevar acttrtvar
          refdatevar actedyvar actsdyvar xovars 
          notexistvars numvisit eventstdtvar eventendtvar periodvars
          eventsttmvar evententmvar durationvar durationuvar exentm exendt
          derivevars reftimevar listvars thisvar loopi xpersdyvar tpersdyvar
          seqvar byvars expdataset sdipcd othervar cycle age_vars birthdt_var;

   %let prefix = _derive;   /* Root name for temporary work datasets */
   %let noderivevars = %qupcase(&noderivevars);
   %let durationunits = %qupcase(&durationunits);
   %let domaincode = %qupcase(&domaincode);
   %let derivevars =;
   
   /*
   / PARAMETER VALIDATION
   /----------------------------------------------------------------------------*/

   /*
   / Check required parameter DSETIN DSETOUT DOMAINCODE are not blank
   /----------------------------------------------------------------------------*/

   %let listvars=DSETIN DSETOUT DOMAINCODE XOVARSFORPGYN;

   %do loopi=1 %to 4;
      %let thisvar=%scan(&listvars, &loopi, %str( ));
      %let &thisvar=%nrbquote(&&&thisvar);

      %if &&&thisvar eq %then
      %do;
         %put %str(RTE)RROR: &sysmacroname: The parameter &thisvar is required.;
         %let g_abort=1;
      %end;
   %end;  /* end of do-to loop */
   
   /* 
   / Check if XOVARSFORPGPGYN is Y or N
   /----------------------------------------------------------------------------*/
   
   %if ( %qupcase(&XOVARSFORPGYN) ne Y ) and ( %qupcase(&XOVARSFORPGYN) ne N ) %then
   %do;
      %put %str(RTE)RROR: &sysmacroname: XOVARSFORPGYN(=&XOVARSFORPGYN) should be either Y or N.;
      %let g_abort=1;
   %end;
      
   /*
   / Check value of DOMAINCODE is one of AE BL CM CY DG DM DS EG EX GP IE LB
   / MD MH MS PN PR PT SD SF SP STG SU TR TS VS VT RU LP LI DS2 IP
   /----------------------------------------------------------------------------*/  
   
   %if %sysfunc(indexw(AE BL CM CY DG DM DS EG EX GP IE LB MD MH MS PN PR PT SD SF SP STG SU TR TS VS VT RU LP LI DS2 IP,&domaincode)) eq 0 %then
   %do;
      %put %str(RTW)ARNING: &sysmacroname: The parameter DOMAINCODE contains a non-standard value: &DOMAINCODE.;
      %let domaincode=_NONE_;
   %end;

   %if &dsetin ne %then
   %do;

   /*
   / Check that required dataset &DSETIN exists.
   /----------------------------------------------------------------------------*/

      %if %tu_nobs(&dsetin) lt 0 %then
      %do;
         %put %str(RTE)RROR: &sysmacroname: The dataset DSETIN(=&dsetin) does not exist.;
         %let g_abort=1;         
      %end;

   /*
   / If the input dataset name is the same as the output dataset name,
   / write a note to the log.
   /----------------------------------------------------------------------------*/

      %if %qscan(&dsetin, 1, %str(%() ) eq %qscan(&dsetout, 1, %str(%() ) %then
      %do;
         %put %str(RTN)OTE: &sysmacroname: The input dataset name DSETIN(=&dsetin) is the same as the output dataset name DSETOUT(=&dsetout).;
      %end;

   %end; /* end-if on &dsetin ne */

   /*
   / Years, Months, Weeks, Days and Hours
   /----------------------------------------------------------------------------*/

   %if %index(EX AE DS2 IP, &domaincode) gt 0 %then
   %do;
      %if (&durationunits ne DAYS) and (&durationunits ne HOURS) and
          (&durationunits ne YEARS) and (&durationunits ne MONTHS) and
          (&durationunits ne WEEKS)
      %then %do;
         %put %str(RTE)RROR: &sysmacroname: DURATIONUNITS(=&durationunits) must be Days, Hours, Years, Months or Weeks.;
         %let g_abort=1;
      %end;
   %end; /* end-if on %index(EX AE, &domaincode) gt 0 */
   
   /*
   / Check noderivedvars
   /----------------------------------------------------------------------------*/
   
   %if &domaincode eq AE %then
   %do;
      %let derivevars=AEACTSDY AEACTEDY AEDUR AEDURC AEDURU AEONGO AETRTST AETRTSTC 
                      AEPTR1ST AEPTR1SC AETRT1ST AETRT1SC AEPERSDY AEPEREDY TPERSDY XPERSDY TPEREDY XPEREDY;
   %end;
   %else %if &domaincode eq BL %then
   %do;
      %let derivevars=BLACTDY BLACTTRT BLPERDY TPERDY XPERDY ;
   %end;
   %else %if &domaincode eq CM %then
   %do;
      %let derivevars=CMACTSDY CMACTEDY CMPERSDY CMPEREDY TPERSDY XPERSDY TPEREDY XPEREDY;
   %end;
   %else %if &domaincode eq DM %then
   %do;
      %let derivevars=DMACTDY DMDT DMREFDT DMREFTM;
   %end;
   %else %if &domaincode eq DS %then
   %do;
      %let derivevars=DSACTDY DSACTTRT DSPERDY TPERDY XPERDY;
   %end;   
   %else %if &domaincode eq DS2 %then
   %do;
      %let derivevars=DSSTDY DSACTTRT PERDY TPERDY XPERDY DSSEQ ;
   %end;   
   %else %if &domaincode eq EG %then
   %do;
      %let derivevars=EGACTDY EGSEQ EGPERDY TPERDY XPERDY EGAGE EGAGEMO EGAGEWK EGAGEDY AGE AGEMO AGEWK AGEDY; /* BA001 Added AGE AGEMO AGEWK AGEDY */
   %end;
   %else %if &domaincode eq EX %then
   %do;
      %let derivevars=EXACTSDY EXACTEDY ACTTRT EXDUR EXDURU DOSETOT DOSECUM RANDNUM EXDURCUM ;
   %end;
   %else %if &domaincode eq GP %then   /* BA001 - Added GPSEQ to be derived */
   %do;
      %let derivevars=GPSEQ;
   %end;
   %else %if &domaincode eq IE %then
   %do;
      %let derivevars=IECRTNUM;
   %end;
   %else %if &domaincode eq LB %then
   %do;
      %let derivevars=LBACTDY LBAGE LBAGEMO LBAGEWK LBAGEDY LBPERDY TPERDY XPERDY AGE AGEMO AGEWK AGEDY; /* BA001 Added AGE AGEMO AGEWK AGEDY */
   %end;
   %else %if &domaincode eq LI %then
   %do;
      %let derivevars=ACTDY PERDY LISEQ TPERDY XPERDY ; 
   %end;
   %else %if &domaincode eq LP %then
   %do;
      %let derivevars=ACTDY PERDY LPSEQ TPERDY XPERDY ; 
   %end;
   %else %if &domaincode eq RU %then
   %do;
      %let derivevars=ACTDY PERDY RUSEQ TPERDY XPERDY RUTRTST RUPTR1ST RUTRT1ST RUSTRTPT RUDT; 
   %end;
   %else %if &domaincode eq MH %then
   %do;
      %let derivevars=MHACTDY MHDT; 
   %end;
   %else %if &domaincode eq MS %then
   %do;
      %let derivevars=DMREFDT DMREFTM;
   %end;
   %else %if &domaincode eq SD %then
   %do;
      %let derivevars=SDACTDY SDACTTRT SDENDT SDENTM SDENDM SDPERDY TPERDY XPERDY;
   %end;
   %else %if &domaincode eq IP %then
   %do;
      %let derivevars=ACTDT ACTDY SDACTTRT SDENDT SDENTM SDENDM PERDY TPERDY XPERDY SDSEQ SDENDY;
   %end;
   %else %if &domaincode eq SF %then
   %do;
      %let derivevars=SFACTDY SFPERDY;
   %end;
   %else %if &domaincode eq SP %then
   %do;
      %let derivevars=SPACTDY SPPERDY TPERDY XPERDY SPENDY SPPEREDY TPEREDY XPEREDY;
   %end;
   %else %if &domaincode eq SU %then
   %do;
      %let derivevars=SUDT SUACTDY SUPERDY TPERDY XPERDY;;
   %end;
   %else %if &domaincode eq VS %then
   %do;
      %let derivevars=VSDT VSBMI VSACTDY VSPERDY TPERDY XPERDY VSAGE VSAGEWK VSAGEDY VSAGEMO VSSEQ AGE AGEMO AGEWK AGEDY; /* BA001 Added AGE AGEMO AGEWK AGEDY */ 
   %end;
   
   %let loopi=1;                                                    
   %let thisvar=%qscan(&noderivevars, &loopi, %str( ));
   
   %do %while( (&thisvar ne ) and (%nrbquote(&derivevars) ne) );
      %if %sysfunc(indexw(&derivevars, &thisvar)) eq 0 %then
      %do;
         %put %str(RTW)ARNING: &sysmacroname: Variable &thisvar specified in parameter NODERIVEVARS (=&noderivevars) is invalid.;
         %put %str(RTW)ARNING: &sysmacroname: It is not one of the variables (=&derivevars) which are derived for DOMAINCODE=&domaincode..;    
      %end;
             
      %let loopi=%eval(&loopi + 1);
      %let thisvar=%qscan(&noderivevars, &loopi, %str( ));
   %end;
   
   %let noderivevars = _NONE_ &noderivevars;

   %if &g_abort eq 1 %then
   %do;
      %tu_abort;
   %end;     

   /*
   / NORMAL PROCESSING
   /----------------------------------------------------------------------------*/

   /*
   / If &DOMAINCODE is one of CY DG MS MD PN PR PT STG TR TS and VT, set
   / &DSETOUT to &DSETIN and exit
   /----------------------------------------------------------------------------*/
   /* BA001 - Removed GP from list so GPSEQ could be derived */
   %if %index(CY DG MD PN PR PT STG TR TS VT, &domaincode) gt 0 %then
   %do;
       %put %str(RTN)OTE: &sysmacroname: There are no derived variables for specified DOMAINCODE (=&domaincode).;
       %let domaincode=_NONE_;
   %end;

   %if &domaincode eq _NONE_ %then
   %do;
       data &dsetout;
          set &dsetin;
       run;

       %goto endmac;
    %end;

   %let domaincode=%unquote(&domaincode);

   /*
   / Initialise counter for appending to temporary dataset names for the
   / purpose of tracking datasets through a number of optional sequential
   / data processing steps.
   /----------------------------------------------------------------------------*/

   %let i = 1;

   data &prefix._temp&i;
      set &dsetin;
   run;

   /*
   / Derivation of STOPDRUG variables.
   / Derived variables: SDENDT SDENTM SDENDM
   /----------------------------------------------------------------------------*/

   %if ( &domaincode eq SD ) or ( &domaincode eq IP ) %then
   %do;   
      %if %sysfunc(indexw(&noderivevars,SDENDT)) eq 0 %then
      %do;
         %if %sysfunc(exist(%qscan(&exposuredset, 1, %str(%() ))) %then
         %do;
            data &prefix._exposure;
               set %unquote(&exposuredset);
            run;
            
            %let expdataset=&prefix._exposure;

            /* YW009: if exendt does not exist, or has no non-missing values, use exstdt */
            %let exendt=exendt;
            %let exentm=exentm;
            
            %if %tu_chkvarsexist(&expdataset, &exendt) ne %then 
            %do;
               %let exendt=exstdt;
               %let exentm=exsttm;
            %end;
            
            %let loopi=0;
                                   
            proc sql noprint;
               select count(&exendt) into :loopi
               from &expdataset             
               where not missing(&exendt);
            quit;
            
            %if &loopi eq 0 %then 
            %do;
               %let exendt=exstdt;                             
               %let exentm=exsttm;
            %end;
            
            %let sdipcd=sdipcd;                                                              
            %if %tu_chkvarsexist(&expdataset, &exentm) ne %then %let exentm=;
            %if %tu_chkvarsexist(&expdataset, EXINVPCD) ne %then %let sdipcd=;
            %if %tu_chkvarsexist(&prefix._temp&i, SDIPCD) ne %then %let sdipcd=;
            
            %if %nrbquote(&sdipcd) ne %then
            %do;                      
               %let loopi=0;                                   
               proc sql noprint;
                  select count(sdipcd) into :loopi
                  from &prefix._temp&i            
                  where not missing(sdipcd);
               quit;
               
               %if &loopi eq 0 %then 
               %do;
                  %let sdipcd=;
                  %put %str(RTN)OTE: &sysmacroname: SDIPCD values in DSETING(=&dsetin) are all missing. SDIPCD will not be used to derive SDENDT.;
               %end;
               
               
               %let loopi=0;                                   
               proc sql noprint;
                  select count(exinvpcd) into :loopi
                  from &expdataset             
                  where not missing(exinvpcd);
               quit;
               
               %if &loopi eq 0 %then 
               %do;
                  %let sdipcd=;                              
                  %put %str(RTN)OTE: &sysmacroname: EXINVPCD values in EXPDATASET(=&expdataset) are all missing. EXINVPCD will not be used to derive SDENDT.;
               %end;
            %end; /* %if %nrbquote(&sdipcd) ne */
            
            /* Get SDENDT and SDENTM from EXPOSURE.EXENDT and EXPOSURE.EXENTM */
            %if %tu_chkvarsexist(&expdataset, exentm) eq %then %let exentm=exentm;
            %else %let exentm=;

            /* BA001 - Get CYCLE from EXPOSURE if it exists and if it does not exist in IPDISC */
            %if %tu_chkvarsexist(&expdataset, cycle) eq AND %tu_chkvarsexist(&prefix._temp&i, cycle) ne %then %let cycle=cycle;
            %else %let cycle=;

            /* BA001 - Add cycle variable to the KEEP list */
            proc sort data=&expdataset(keep=studyid subjid &cycle &exendt &exentm
               %if %nrbquote(&sdipcd) ne %then exinvpcd rename=(exinvpcd=&sdipcd);) out=&prefix._exposure;
               by studyid subjid &sdipcd &exendt &exentm;
            run;

            data &prefix._end_expo;
               set &prefix._exposure;
               by studyid subjid &sdipcd;
               if last.%scan(subjid &sdipcd, -1);
               
               rename &exendt=sdendt;
               
               %if %nrbquote(&exentm) ne  %then
               %do;
                  rename &exentm=sdentm;
               %end;
            run;

            proc sort data=&prefix._temp&i;
               by studyid subjid &sdipcd;
            run;

            data &prefix._temp%eval(&i+1);
               merge &prefix._temp&i(in=A) &prefix._end_expo;
               by studyid subjid &sdipcd;
               if A;

               %if %nrbquote(&exentm) ne %then
               %do;
                  sdendm=86400*sdendt+sdentm; /* Number of seconds in a day is 86400. */
               %end;
            run;

            %let i = %eval(&i + 1);
            
         %end;
         %else %do;
            %put %str(RTW)ARNING: &sysmacroname: The parameter EXPOSUREDSET(=&EXPOSUREDSET) specifies a dataset which does not exist.;
            %put %str(RTW)ARNING: &sysmacroname: The derived variable SDENDT has been set to missing.;
            data &prefix._temp%eval(&i+1);
               set &prefix._temp&i;
               sdendt=.;
            run;

            %let i = %eval(&i + 1);
         %end;
      %end; /* %if %sysfunc(indexw(&noderivevars,SDENDT)) eq 0 */
   %end; /* DOMAINCODE=SD or DOMAINCODE=IP */

   /*
   /  For &DOMAINCODE in DM, MH, VS,and IP, calling %tu_visit to derive DMDT, MHDT,
   /  SUDT or VSDT from the visit date
   /  Derived Variables:  DMDT, MHDT VSDT SUDT ACTDT RUDT 
   /----------------------------------------------------------------------------*/

   %let vsdtvar=;

   %if %index(DM MH VS SU RU, &domaincode) gt 0 %then
   %do;
      %let vsdtvar=&domaincode.DT;      
      %if %sysfunc(indexw(&noderivevars, %qupcase(&vsdtvar))) ne 0 %then %let vsdtvar=;
   %end;
   
   %if &domaincode eq IP %then
   %do;
      %let vsdtvar=ACTDT;      
      %if %sysfunc(indexw(&noderivevars, %qupcase(&vsdtvar))) ne 0 %then %let vsdtvar=;
   %end;
  
   %if %nrbquote(&vsdtvar) ne %then
   %do;
      %if %tu_chkvarsexist(&prefix._temp&i, &vsdtvar) ne %then
      %do;           
         %if %tu_chkvarsexist(&prefix._temp&i, VISITNUM) eq %then
         %do;    
            %tu_visitdt(
                dsetin    =&prefix._temp&i,
                dsetout   =&prefix._temp%eval(&i+1),
                visitdset =&visitdset,
                varname   =&vsdtvar.
                );                
            %let i = %eval(&i + 1);
         %end;
         %else %do;     
            /* VISITNUM is not required for DM and MH */
            %if &domaincode eq DM or &domaincode eq MH %then 
               %put %str(RTN)OTE: &sysmacroname: VISITNUM does not exist in input data set and variable &vsdtvar will not be derived.;
            %else    
               %put %str(RTW)ARNING: &sysmacroname: VISITNUM does not exist in input data set and variable &vsdtvar will not be derived.;
         %end;
      %end;
      %else %do;
         %put %str(RTN)OTE: &sysmacroname: Variable &vsdtvar is already in input data set and will not be derived.;
      %end; /* end-if on %tu_chkvarsexist(&prefix._temp&i, &vsdtvar) ne */
   %end; /* end-if on %nrbquote(&vsdtvar) ne */

   /*
   / If &DOMAINCODE in AE BL CM DS DS2 EG LB SD, IP, SF SP SU or VS, derive 
   / actual period days from event date and period start date by calling 
   / %tu_perstd. For &domaincode equals AE, event AEPERSDY is not required, if    
   / AEPTR1ST is required, %tu_perstd also needs to be called.
   / Derived Variables: AEPERSDY BLPERDY CMPERSDY DSPERDY EGPERDY LBPERDY
   /                    SDPERDY SFPERDY SPPERDY SUPERDY VSPERDY XPERDY PERDY
   /----------------------------------------------------------------------------*/
  
   %let perstdt=;
   %let tpersdyvar=;
   %let xpersdyvar=;
   %let xovars=; /* list of crossover study variables */

   /* AEPERSDY, TPERSDY, XPERSDY: Actual day within period of start of event */
   
   %if &domaincode eq AE %then
   %do;
      %let datevar=aestdt;
      %let timevar=aesttm;
      %let perstdt=aepersdy;
      %let tpersdyvar=tpersdy;
      %let xpersdyvar=xpersdy;     
      %let xovars=&xovars AEPTR1ST AEPTR1SC AEPEREDY TPEREDY XPEREDY;
   %end;

   /* BLPERDY, TPERDY, XPERDY: Actual day within period blind was broken */
   
   %if &domaincode eq BL %then
   %do;
      %let datevar=bldt;
      %let timevar=bltm;
      %let tpersdyvar=tperdy;
      %let xpersdyvar=xperdy;  
      %let perstdt=blperdy;
   %end;

   /* CMPERSDY, TPERSDY, XPERSDY: Actual day within period of start of med */
   %if &domaincode eq CM %then
   %do;
      %let datevar=cmstdt;
      %let timevar=cmsttm;
      %let perstdt=cmpersdy;
      %let tpersdyvar=tpersdy;
      %let xpersdyvar=xpersdy;  
      %let xovars=&xovars CMPEREDY TPEREDY XPEREDY;
   %end;

   /* DSPERDY, TPERDY, XPERDY: Period day of completion or withdrawal    */
   %if &domaincode eq DS %then
   %do;
      %let datevar=dsdt;
      %let timevar=dswdtm;
      %let perstdt=dsperdy;
      %let tpersdyvar=tperdy;
      %let xpersdyvar=xperdy;  
   %end;
   
   /* DSPERDY, TPERDY, XPERDY: Period day of completion or withdrawal    */
   %if &domaincode eq DS2 %then
   %do;
      %let datevar=dsstdt;
      %let timevar=;
      %let perstdt=perdy;
      %let tpersdyvar=tperdy;
      %let xpersdyvar=xperdy;  
   %end;

   /* EGPERDY, TPERDY, XPERDY: Actual day within period of collection */
   %if &domaincode eq EG %then
   %do;
      %let datevar=egdt;
      %let timevar=egacttm;
      %let perstdt=egperdy;
      %let tpersdyvar=tperdy;
      %let xpersdyvar=xperdy;  
   %end;

   /* LBPERDY, TPERDY, XPERDY: Actual day within period of event */
   %if &domaincode eq LB %then
   %do;
      %let datevar=lbdt;
      %let timevar=lbacttm;
      %let perstdt=lbperdy;
      %let tpersdyvar=tperdy;
      %let xpersdyvar=xperdy;  
   %end;

   /* SDPERDY, TPERDY, XPERDY: Actual day within period */
   %if &domaincode eq SD %then
   %do;
      %let datevar=sdendt;
      %let timevar=sdentm;
      %let perstdt=sdperdy;
      %let tpersdyvar=tperdy;
      %let xpersdyvar=xperdy;  
   %end;
   
   /* PERDY, TPERDY, XPERDY: Actual day within period */
   %if &domaincode eq IP %then
   %do;
      %let datevar=sdendt;
      %let timevar=sdentm;
      %let perstdt=perdy;
      %let tpersdyvar=tperdy;
      %let xpersdyvar=xperdy;  
   %end;
   
   %if %sysfunc(indexw(LI LP, &domaincode)) gt 0 %then
   %do;
      %let datevar=&domaincode.DT;
      %let timevar=;
      %let perstdt=perdy;
      %let tpersdyvar=tperdy;
      %let xpersdyvar=xperdy;       
   %end;
   
   %if &domaincode eq RU %then
   %do;
      %let datevar=RUDT;
      %let timevar=;
      %let perstdt=perdy;
      %let tpersdyvar=tperdy;
      %let xpersdyvar=xperdy;       
      %let xovars=&xovars RUPTR1ST;
   %end;      
  
   /* SFPERDY, TPERDY, XPERDY: Actual day within period of run-in or screen failure */
   %if &domaincode eq SF %then
   %do;
      %let datevar=sfdt;
      %let timevar=;
      %let perstdt=sfperdy;
      %let tpersdyvar=;
      %let xpersdyvar=;  
   %end;
   
   /* SPPERDY, TPERDY, XPERDY: Actual day within period of surgery */
   %if &domaincode eq SP %then
   %do;
      %let datevar=spdt;
      %let timevar=spacttm;
      %let perstdt=spperdy;
      %let tpersdyvar=tperdy;
      %let xpersdyvar=xperdy;  
      %let xovars=&xovars SPPEREDY TPEREDY XPEREDY;
   %end;
   
   /* SUPERDY, TPERDY, XPERDY: Period day of Assessment */
   %if &domaincode eq SU %then
   %do;
      %let datevar=sudt;
      %let timevar=;
      %let perstdt=superdy;
      %let tpersdyvar=tperdy;
      %let xpersdyvar=xperdy;  
   %end;

   /* VSPERDY, TPERDY, XPERDY: Actual day within period of collection.   */
   %if &domaincode eq VS %then
   %do;
      %let datevar=vsdt;
      %let timevar=vsacttm;
      %let perstdt=vsperdy;
      %let tpersdyvar=tperdy;
      %let xpersdyvar=xperdy;  
   %end;
   
   %let xovars=&xovars &perstdt;
   
   %if %sysfunc(indexw(&noderivevars, %qupcase(&tpersdyvar))) ne 0 %then %let tpersdyvar=;
   %if %sysfunc(indexw(&noderivevars, %qupcase(&xpersdyvar))) ne 0 %then %let xpersdyvar=;
   
   %let xovars=&xovars &tpersdyvar &xpersdyvar;

   /*
   /  Variable &XOVARS is/are for crossover study. If the study is parallel,
   /  write a RTNOTE to the log.
   /---------------------------------------------------------------------------*/

   %if ( %qupcase(&XOVARSFORPGYN) eq N ) and ( %qupcase(&g_stype) eq PG ) and ( %nrbquote(&xovars) ne ) %then
   %do;
      %put %str(RTN)OTE: &sysmacroname: Period related variable &xovars will not be derived for parallel study.;
      %let noderivevars=&noderivevars %upcase(&xovars);
   %end;

   /*
   /  If AEPERSY is not required, %tu_perstd is also need to be called for
   /  AEPTR1ST
   /---------------------------------------------------------------------------*/

   %if ( &domaincode eq AE ) and ( %sysfunc(indexw(&noderivevars, AEPERSDY)) gt 0 ) 
       and ( %sysfunc(indexw(&noderivevars, AEPTR1ST)) eq 0 ) %then
   %do;
      %let perstdt=AEPTR1ST;
   %end;
      
   %if ( &domaincode eq RU ) and ( %sysfunc(indexw(&noderivevars, PERDY)) gt 0 ) 
       and ( %sysfunc(indexw(&noderivevars, RUPTR1ST)) eq 0 ) %then
   %do;
      %let perstdt=RUPTR1ST;
   %end;
   
   /* YW009: check if &PERSTDT is in &NODERIVEVARS before varifying other vairables */   
   %if %nrbquote(&perstdt) ne %then
   %do;
      %if %sysfunc(indexw(&noderivevars, %qupcase(&perstdt))) gt 0 %then %let perstdt=;      
   %end;
   
   %if %nrbquote(&perstdt) ne %then
   %do;
      %if %nrbquote(&timevar) ne %then
      %do;  
         %if %tu_chkvarsexist(&prefix._temp&i, &timevar) ne %then
         %do;
            %put %str(RTN)OTE: &sysmacroname: Time variable &timevar does not exist in DSETIN (=&dsetin) and will not be used to derive &perstdt.;
            %let timevar=;
         %end;
      %end; 
      %else %do;
         %put %str(RTN)OTE: &sysmacroname: Time variable is not given and will not be used to derive &perstdt.;
      %end; /* end-if on %nrbquote(&timevar) ne */
      
      %if %tu_chkvarsexist(&prefix._temp&i, &datevar) ne %then
      %do;
         %put %str(RTW)ARNING: &sysmacroname: Variable &datevar does not exist in DSETIN (=&dsetin). Variable &perstdt can not be derived.;
         %let timevar=;
      %end;     
      %else %if %tu_chkvarsexist(&prefix._temp&i, &perstdt) eq %then
      %do;
         %put %str(RTW)ARNING: &sysmacroname: Variable &perstdt already exists in DSETIN (=&dsetin) and will not be derived.;
      %end;
      %else %do;

         %tu_perstd(
            dsetin       =&prefix._temp&i,
            dsetout      =&prefix._temp%eval(&i+1),
            exposuredset =&exposuredset,
            refdat       =&datevar,
            reftim       =&timevar,
            tmslicedset  =&tmslicedset,
            varname      =&perstdt,
            vartname     =&tpersdyvar,
            varxname     =&xpersdyvar,
            visitdset    =&visitdset
            );                    
                     
         %let i = %eval(&i + 1);      
                  
      %end; /* end-if on %index(&noderivevars, &perstdt) gt 0 */

   %end; /* end-if on %nrbquote(&perstdt) ne */

   /*
   /  If &DOMAINCODE in EX BL DS DS2 IP or SD, derive actual treatment at the    
   /  time of the event by calling %tu_acttrt
   /  Derived Variables: BLACTTRT DSACTTRT SDACTTRT ACTTRT
   /----------------------------------------------------------------------------*/

   %let acttrtvar=;
   
   /* ACTTRT: Actual Treatment  */
   %if &domaincode eq EX %then
   %do;
      %let datevar=exstdt;
      %let timevar=exsttm;
      %let acttrtvar=acttrt;
   %end;

   /* BLACTTRT: Treatment at time when blind was broken  */
   %if &domaincode eq BL %then
   %do;
      %let datevar=bldt;
      %let timevar=bltm;
      %let acttrtvar=blacttrt;
   %end;

   /* DSACTTRT: Treatment at completion or withdrawal    */
   %if &domaincode eq DS %then
   %do;
      %let datevar=dsdt;
      %let timevar=dswdtm;
      %let acttrtvar=dsacttrt;
   %end;
   
   /* DSACTTRT: Treatment at completion or withdrawal    */
   %if &domaincode eq DS2 %then
   %do;
      %let datevar=dsstdt;
      %let timevar=;
      %let acttrtvar=dsacttrt;
   %end;      

   /* SDACTTRT: Treatment at time when inv product stopped. */
   %if &domaincode eq SD or  &domaincode eq IP %then
   %do;
      %let timevar=sdentm;
      %let datevar=sdendt;
      %let acttrtvar=sdacttrt;
   %end;

   %if %nrbquote(&acttrtvar) ne %then
   %do;
      %if %nrbquote(&timevar) ne %then
      %do;
         %if %tu_chkvarsexist(&prefix._temp&i, &timevar) ne %then
         %do;
            %put %str(RTN)OTE: &sysmacroname: Time variable &timevar does not exist in DSETIN (=&dsetin) and will not be used to derive &acttrtvar.;
            %let timevar=;
         %end;
      %end; /* %if %nrbquote(&timevar) ne */
      
      %if %tu_chkvarsexist(&prefix._temp&i, &datevar) ne %then
      %do;
         %if %qupcase(&g_stype) eq PG %then
         %do;
            %put %str(RTW)ARNING: &sysmacroname: Variable &datevar does not exist in DSETIN (=&dsetin) and will not be used to derive &acttrtvar.;         
            %let datevar=;
         %end;
         %else %do;
            %put %str(RTW)ARNING: &sysmacroname: Variable &datevar does not exist in DSETIN (=&dsetin) and &acttrtvar can not be derived.;         
            %let noderivevars=&noderivevars %qupcase(&acttrtvar);         
         %end;
      %end; /* end-if on  %tu_chkvarsexist(&prefix._temp&i, &datevar) ne */     
      
      %if %tu_chkvarsexist(&prefix._temp&i, &acttrtvar) eq %then
      %do;
         %put %str(RTW)ARNING: &sysmacroname: Variable &acttrtvar already exists in DSETIN (=&dsetin) and will not be derived.;
      %end;
      %else %if %sysfunc(indexw(&noderivevars, %qupcase(&acttrtvar))) eq 0 %then
      %do;
         %if &domaincode EQ EX %then
         %do; 
            %let datevar=__exstdt;
            %if %nrbquote(&timevar) ne %then %let timevar=__exsttm;

            data &prefix._temp&i;
               set &prefix._temp&i;
               rename exstdt=__exstdt %if %nrbquote(&timevar) ne %then exsttm=__exsttm;;
            run;
         %end; 
         
         %tu_acttrt(
            dsetin      =&prefix._temp&i,
            dsetout     =&prefix._temp%eval(&i+1),
            exposuredset=&exposuredset,
            randdset    =&randdset,
            randalldset =&randalldset,
            refdat      =&datevar,
            reftim      =&timevar,
            tmslicedset =&tmslicedset,
            varname     =&acttrtvar,
            visitdset   =&visitdset
            );
          
         %let i = %eval(&i + 1);
         
         %if &domaincode EQ EX %then
         %do; 
            data &prefix._temp&i;
               set &prefix._temp&i;
               rename __exstdt=exstdt %if %nrbquote(&timevar) ne %then __exsttm=exsttm;;
            run;
         %end;                              
      %end; /* end-if on %index(&noderivevars, %qupcase(&acttrtvar)) eq 0 */
   %end; /* end-if on %nrbquote(&acttrtvar) ne */
                                                                              
   /*
   / If &DOMAINCODE in AE CM EX BL DM DS EG LB MH SD SF or VS, derive actual
   / treatment days from event date and treatment start date. Treatment start
   / is derived by calling %tu_refdat
   / derived variables: AEACTSDY AEACTEDY CMACTSDY CMACTEDY EXACTSDY EXACTEDY
   /                    BLACTDY DMACTDY DSACTDY EGACTDY LBACTDY MHACTDY
   /                    SDACTDY SFACTDY SPACTDY SUACTDY VSACTDY DMREFTM DMREFDT
   /----------------------------------------------------------------------------*/

   %let refdatevar=_temp_refdat;
   %let reftimevar=;
   %let actedyvar=;
   %let actsdyvar=;
   %let eventstdtvar=;
   %let eventendtvar=;

   %if %index(AE CM EX, &domaincode) gt 0 %then
   %do;
      %let actsdyvar=&domaincode.ACTSDY;
      %let actedyvar=&domaincode.ACTEDY;
      %let eventstdtvar=&domaincode.STDT;
      %let eventendtvar=&domaincode.ENDT;
   %end;
   
   %if &domaincode eq SP %then
   %do;
      %let actsdyvar=&domaincode.ACTDY;
      %let actedyvar=&domaincode.ENDY;
      %let eventstdtvar=&domaincode.DT;
      %let eventendtvar=&domaincode.ENDT;
   %end;      
   
   %if &domaincode eq EG %then
   %do;
      %let actsdyvar=EGACTDY;
      %let eventstdtvar=EGDT;
   %end;    
   
   %if &domaincode eq IP %then 
   %do;
      %let actsdyvar=ACTDY;
      %let actedyvar=SDENDY;
      %let eventstdtvar=ACTDT;
      %let eventendtvar=SDENDT;
   %end;   
   
   %if &domaincode eq DS2 %then 
   %do;
      %let actsdyvar=DSSTDY;
      %let eventstdtvar=DSSTDT;
   %end;  
   
   %if %sysfunc(indexw(LI RU LP, &domaincode)) gt 0 %then
   %do;
      %let actsdyvar=ACTDY;
      %let eventstdtvar=&domaincode.DT;
   %end;
   
   %if %sysfunc(indexw(BL DM DS LB MH SD SF SU VS, &domaincode)) gt 0 %then
   %do;
      %let actsdyvar=&domaincode.ACTDY;
      %let eventstdtvar=&domaincode.DT;
   %end;
   
   %if &domaincode eq SD %then %let eventstdtvar=SDENDT;
   
   %if ( &domaincode eq DM ) or ( &domaincode eq MS ) %then %do;
      %let refdatevar=dmrefdt;
      %let reftimevar=dmreftm;
   %end;

   %if %nrbquote(&actsdyvar) ne %then
   %do;
      %if %sysfunc(indexw(&noderivevars, %qupcase(&actsdyvar))) gt 0 %then
      %do;
         %let actsdyvar=;
      %end;
      %else %do;
         %if %tu_chkvarsexist(&&prefix._temp&i, &eventstdtvar) ne %then %do;
            %if &domaincode ne MH and &domaincode ne DM %then
               %put %str(RTW)ARNING: &sysmacroname: Can not derive &ACTSDYVAR, because &EVENTSTDTVAR does not exist.;
            %else
               %put %str(RTN)OTE: &sysmacroname: Can not derive &ACTSDYVAR, because &EVENTSTDTVAR does not exist.;
               
            %let actsdyvar=;
         %end;
      %end; /* end-if on %index(&noderivevars, &actsdyvar) gt 0 */
   %end; /* end-if on %nrbquote(&actsdyvar) ne */

   %if ( &refdatevar ne _temp_refdat ) and %sysfunc(indexw(&noderivevars, %qupcase(&refdatevar))) gt 0 %then
   %do;
      %let refdatevar=_temp_refdat;
   %end;
   
   %if %nrbquote(&actedyvar) ne %then
   %do;
      %if %sysfunc(indexw(&noderivevars, %qupcase(&actedyvar))) gt 0 %then
      %do;      
         %let actedyvar=;
      %end;
      %else %do;
         %if %tu_chkvarsexist(&&prefix._temp&i, &eventendtvar) ne %then
         %do;
            %put %str(RTW)ARNING: &sysmacroname: Can not derive &ACTEDYVAR, because &EVENTENDTVAR does not exist.;
            %let actedyvar=;
         %end;
      %end; /* end-if on %index(&noderivevars, &actedyvar) gt 0 */
   %end; /* end-if on %nrbquote(&actedyvar) ne */

   %if  (%nrbquote(&actsdyvar.&actedyvar) ne ) or ( &refdatevar ne _temp_refdat ) %then
   %do;
      %tu_refdat(
         dsetin            = &prefix._temp&i,
         dsetout           = &prefix._temp%eval(&i+1),
         exposuredset      = &exposuredset,         
         randdset          = &randdset,     
         refdatevar        = &refdatevar,
         reftimevar        = &reftimevar,
         refdateoption     = &refdateoption,
         refdatevisitnum   = &refdatevisitnum,
         refdatesourcedset = &refdatesourcedset,
         refdatesourcevar  = &refdatesourcevar,
         reftimesourcevar  = &reftimesourcevar,
         refdatedsetsubset = &refdatedsetsubset,
         visitdset         = &visitdset
         );          

      %let i = %eval(&i + 1);

      data &prefix._temp%eval(&i+1);
         set &prefix._temp&i;

         /* Actual study day from the start of the event */
         %if %nrbquote(&actsdyvar) ne %then
         %do;
            if ( &eventstdtvar ne .) and (  &refdatevar ne . ) then
            do;
               if &eventstdtvar ge &refdatevar then &actsdyvar=&eventstdtvar - &refdatevar + 1;
               else &actsdyvar=&eventstdtvar - &refdatevar;
            end;
         %end;

         /* Actual study day from the end of the event */
         %if %nrbquote(&actedyvar) ne %then
         %do;
            if ( &eventendtvar ne .) and (  &refdatevar ne . ) then
            do;
               if ( &eventendtvar ge &refdatevar ) then &actedyvar=&eventendtvar - &refdatevar + 1;
               else &actedyvar=&eventendtvar - &refdatevar;
            end;
         %end;
      run;

      %let i = %eval(&i + 1);
   %end;

   /*
   / If &DOMAINCODE in AE or EX, derive event duration.
   / Devived varirables: AEDUR AEDURU EXDUR EXDURU
   /----------------------------------------------------------------------------*/

   %let eventstdtvar=;
   %let eventendtvar=;
   %let eventsttmvar=;
   %let evententmvar=;
   %let durationvar=;
   %let durationuvar=;

   %if %index(AE EX, &domaincode) gt 0 %then
   %do;
      %let eventstdtvar=&domaincode.STDT;
      %let eventendtvar=&domaincode.ENDT;
      %let eventsttmvar=&domaincode.STTM;
      %let evententmvar=&domaincode.ENTM;
      %let durationvar=&domaincode.DUR;
      %let durationuvar=&domaincode.DURU;
   %end;

   %if %sysfunc(indexw(&noderivevars, &durationvar)) gt 0 %then
   %do;
      %let durationvar=;
   %end;

   %if %sysfunc(indexw(&noderivevars, &durationuvar)) gt 0 %then
   %do;
      %let durationuvar=;
   %end;

   /* Duration units */
   %if %nrbquote(&durationuvar) ne %then
   %do;
       data &prefix._temp%eval(&i+1);
          set &prefix._temp&i;
          &domaincode.duru=lowcase(substr(left("&durationunits"), 1, 2));
          if &domaincode.duru ne 'mo' then
             &domaincode.duru=substr(&domaincode.duru, 1, 1);
       run;
       %let i = %eval(&i + 1);
   %end; /* end-if on %nrbquote(&durationuvar) ne */

   /* Duration */
   %if %nrbquote(&durationvar) ne %then
   %do;
      %if %tu_chkvarsexist(&prefix._temp&i, &eventsttmvar &evententmvar) ne %then
      %do;
         %let eventsttmvar=;
         %let evententmvar=;
      %end;

      data &prefix._temp%eval(&i+1);
         set &prefix._temp&i;

         %if &durationunits eq YEARS %then
         %do;   /* GK001 added missing parenthesis at the end */
            &durationvar=intck('year', &eventstdtvar, &eventendtvar + 1) -
                         ( ( month(&eventendtvar + 1) lt month(&eventstdtvar) ) or
                         ( ( month(&eventendtvar + 1) eq month(&eventstdtvar) ) and
                           ( day(&eventendtvar + 1)   lt day(&eventstdtvar)   ) ) );
         %end;
         %else %if &durationunits eq MONTHS %then
         %do;
            &durationvar=( year(&eventendtvar + 1) - year(&eventstdtvar) ) * 12 +
                         ( month(&eventendtvar + 1) - month(&eventstdtvar) - 1) +
                         ( day(&eventendtvar + 1) ge day(&eventstdtvar) );
         %end;
         %else %if &durationunits eq WEEKS %then
         %do;
            &durationvar=((&eventendtvar + 1) - &eventstdtvar)/7;
         %end;
         %else %if &durationunits eq DAYS %then
         %do;
            &durationvar=(&eventendtvar + 1) - &eventstdtvar;
         %end;
         %else %if &durationunits eq HOURS %then
         %do;
            &durationvar=(&eventendtvar - &eventstdtvar) * 3600 * 24; /* convert to seconds */

            %if %nrbquote(&eventsttmvar) ne %then
            %do;
               if ( &evententmvar gt . ) and ( &eventsttmvar gt . ) then
                  &durationvar=&durationvar + (&evententmvar - &eventsttmvar );
            %end;

            &durationvar=&durationvar / 3600;

            if &durationvar eq ceil( &durationvar ) then
            do;
               &durationvar=&durationvar + 1;
            end;
            else do;
               &durationvar=ceil(&durationvar);
            end;
         %end;
      run;

      %let i = %eval(&i + 1);

   %end;
   
   /*
   / Derivation of SEQUENCE variables.
   / Derived variables: DSSEQ SDSEQ LISEQ LPSEQ RUSEQ
   /----------------------------------------------------------------------------*/
   
   %let timevar=;
   %let seqvar=;
   %let thisvar=;
   %let othervar=;

/* BA001: Added derived GPSEQ variable for Genpro dataset */
   %if &domaincode eq GP %then 
   %do; 
      %let seqvar=GPSEQ;   
      %let datevar=gpcnsdt;
      %let othervar=smptycd;
   %end;
   %if &domaincode eq IP %then 
   %do; 
      %let seqvar=SDSEQ;   
      %let datevar=actdt;
   %end;
   %if &domaincode eq DS2 %then 
   %do; 
      %let seqvar=DSSEQ;   
      %let datevar=dsstdt;
   %end;
   %if &domaincode eq RU %then 
   %do; 
      %let seqvar=RUSEQ;   
      %let datevar=rudt;
      %let thisvar=rutestcd;
      %let othervar=ruorrscd;
   %end;
   %if &domaincode eq LI %then 
   %do; 
      %let seqvar=LISEQ;   
      %let datevar=lidt;
      %let thisvar=litestcd;
      %let othervar=liorrscd;
   %end;
   %if &domaincode eq LP %then 
   %do; 
      %let seqvar=LPSEQ;   
      %let datevar=lpdt;
      %let thisvar=lptestcd;
      %let othervar=lporrscd;
   %end;
   %if &domaincode eq VS %then 
   %do; 
      %let seqvar=VSSEQ;   
      %let datevar=vsdt;
      %let timevar=vsacttm; 
      %let thisvar=vstestcd;     
   %end;
   %if &domaincode eq EG %then 
   %do; 
      %let seqvar=EGSEQ;   
      %let datevar=egdt;
      %let timevar=egacttm; 
      %let thisvar=egtestcd;     
   %end;
         
   %if %nrbquote(&seqvar) ne %then
   %do;   
      %if %sysfunc(indexw(&noderivevars, &seqvar)) gt 0 %then %let seqvar=;
      %else %if %tu_chkvarsexist(&prefix._temp&i, &seqvar) eq %then %let seqvar=;
   %end;
   
   %if %nrbquote(&seqvar) ne  %then
   %do;   
      %let byvars=studyid subjid ;      
      %if %nrbquote(&thisvar) ne %then
      %do;      
         %if %tu_chkvarsexist(&prefix._temp&i, &thisvar) eq %then %let byvars=&byvars &thisvar;
      %end;        
      %if %tu_chkvarsexist(&prefix._temp&i, &datevar) eq %then %let byvars=&byvars &datevar;      
      %if %nrbquote(&timevar) ne %then
      %do;
         %if %tu_chkvarsexist(&prefix._temp&i, &timevar) eq %then %let byvars=&byvars &timevar;
      %end;
      %if %tu_chkvarsexist(&prefix._temp&i, cycle) eq %then %let byvars=&byvars cycle;
      %if %tu_chkvarsexist(&prefix._temp&i, visitnum) eq %then %let byvars=&byvars visitnum;          
      %if %nrbquote(&othervar) ne %then
      %do;
         %if %tu_chkvarsexist(&prefix._temp&i, &othervar) eq %then %let byvars=&byvars &othervar;
      %end;
     
      proc sort data=&prefix._temp&i;
         by &byvars;
      run;   
     
      data &prefix._temp%eval(&i+1);
         set &prefix._temp&i;         
         by &byvars;
         retain &seqvar;
         if first.subjid then &seqvar=0;
         if missing(&datevar) then &seqvar=.;
         else if missing(&seqvar) then &seqvar=0;
         &seqvar=&seqvar + 1;         
      run;      
      
      %let i = %eval(&i + 1);       

   %end; /* %if %sysfunc(indexw(&noderivevars, &seqvar)) gt 0 */
      
   /*
   / Derive variables for period day from end period: SPPEREDY AEPEREDY CMPEREDY
   / TPEREDY, XPEREDY for domin AE, CM, and SP
   /
   / NOTE: For CMPEREDY, the algorithm has been clarified to specify the number of  
   /       days to end of med from the beginning of the period where the start of  
   /       med occurred.    
   /       For AEPEREDY, the algorithm has been clarified to specify the number of 
   /       days to end of event from the beginning of the period where the 
   /       start of event occurred.       
   /----------------------------------------------------------------------------*/
   
   %let actedyvar=;
   %let actsdyvar=;
   %let eventstdtvar=;
   %let eventendtvar=;

   %if %index(AE CM, &domaincode) gt 0 %then
   %do;
      %let actsdyvar=&domaincode.PERSDY;
      %let actedyvar=&domaincode.PEREDY;
      %let eventstdtvar=&domaincode.STDT;
      %let eventendtvar=&domaincode.ENDT;      
      %let tpersdyvar=tpersdy;
      %let xpersdyvar=xpersdy; 
   %end;
   
   %if &domaincode eq SP %then
   %do;
      %let actsdyvar=&domaincode.PERDY;
      %let actedyvar=&domaincode.PEREDY;
      %let eventstdtvar=&domaincode.DT;
      %let eventendtvar=&domaincode.ENDT;
      %let tpersdyvar=tperdy;
      %let xpersdyvar=xperdy;      
   %end;
   
   %if %nrbquote(&actedyvar) ne %then
   %do;
      
      %if ( %sysfunc(indexw(&noderivevars, &actedyvar)) eq 0 ) or 
          ( %sysfunc(indexw(&noderivevars, TPEREDY)) eq 0 ) or 
          ( %sysfunc(indexw(&noderivevars, XPEREDY)) eq 0 ) %then
      %do;
          %if %tu_chkvarsexist(&prefix._temp&i, &eventstdtvar &eventendtvar) eq %then 
          %do;
             data &prefix._temp%eval(&i+1);
                set &prefix._temp&i;   
                if ( &eventendtvar ne . ) and ( &eventstdtvar ne . ) then
                do;
                   &actedyvar = &eventendtvar - &eventstdtvar + &actsdyvar;                   
                   if &actsdyvar lt 0 and &actedyvar ge 0 then &actedyvar=&actedyvar + 1;
                                                       
                   TPEREDY = &eventendtvar - &eventstdtvar + &tpersdyvar;             
                   if &tpersdyvar lt 0 and TPEREDY ge 0 then TPEREDY=TPEREDY + 1;
                   
                   XPEREDY = &eventendtvar - &eventstdtvar + &xpersdyvar;
                   if &xpersdyvar lt 0 and XPEREDY ge 0 then XPEREDY=XPEREDY + 1;
                end;
             run;
             
             %let i=%eval(&i + 1);
          %end;          
          %else %do;          
             %put %str(RTN)OTE: TU_DERIVE: Can not derive &actedyvar, TPEREDY and XPEREDY, because &eventendtvar or &eventstdtvar does not exist in data set &dsetin.;
          %end;
      %end; /* %if %tu_chkvarsexist(&prefix._temp&i, &eventstdtvar &eventendtvar) eq */  
      
   %end; /* %if %nrbquote(&actedyvar) ne %then */                           
   
   /*
   / Derive AGE variable at a time point:
   /    VSAGE:   Age of subject at VSDT in years. 
   /    VSAGEMO: Age of subject at VSDT in months.
   /    VSAGEWK: Age of subject at VSDT in weeks. 
   /    VSAGEDY: Age of subject at VSDT in days.  
   /    LBAGE:   Age of subject at LBDT in years.  
   /    LBAGEMO: Age of subject at LBDT in months. 
   /    LBAGEWK: Age of subject at LBDT in weeks.  
   /    LBAGEDY: Age of subject at LBDT in days.   
   /    EGAGE:   Age of subject at EGDT in years.  
   /    EGAGEMO: Age of subject at EGDT in months. 
   /    EGAGEWK: Age of subject at EGDT in weeks.  
   /    EGAGEDY: Age of subject at EGDT in days.      
   
   /----------------------------------------------------------------------------*/
   
   %let datevar=;
      
   %if %index(LB EG VS, &domaincode) gt 0 %then
   %do;
      %let datevar=&domaincode.DT;
   %end;
     
   %if %nrbquote(&datevar) ne %then
   %do;
   
       %if %nrbquote(&demodset) eq %then
       %do;
          %put %str(RTN)OTE: TU_DERIVE: The parameter DEMODSET is blank.;          
          %put %str(RTN)OTE: TU_DERIVE: The derived variables &domaincode.AGE, &domaincode.AGEMO, &domaincode.AGEWK, and &domaincode.AGEDY have been set to missing.;       
          %let datevar=;
       %end;
       %else %if %sysfunc(exist(%qscan(&demodset, 1, %str(%() ))) le 0 %then
       %do;      
          %put %str(RTN)OTE: TU_DERIVE: The parameter DEMODSET(=&demodset) specifies a dataset which does not exist.;
          %put %str(RTN)OTE: TU_DERIVE: The derived variables &domaincode.AGE, &domaincode.AGEMO, &domaincode.AGEWK, and &domaincode.AGEDY have been set to missing.;
          %let datevar=;
       %end;
          
       %if %nrbquote(&datevar) ne %then
       %do;
          data &prefix.demo;
             set %unquote(&demodset);
          run;

       /* BA001
       /* If BIRHTDT does not exist or all missing then get AGE variables from &DEMODSET.
       /*-------------------------------------------------------------------------------------*/
          %let age_vars =;
          %let birthdt_var =;

          proc sql noprint;
             select count(*) into :birthdt_var
                from dictionary.columns 
                where libname = 'WORK' AND
                      memname = "%upcase(&prefix.demo)" AND
                      memtype = 'DATA' AND
                      upcase(name) = 'BIRTHDT';       /* Check if BIRTHDT var exists */
          quit;

          %if &birthdt_var %then     /* If BIRTHDT exists check if all values are missing */
          %do;
             %let birthdt_var =;
             proc sql noprint;
                select count(*) into :birthdt_var
                   from &prefix.demo
                   where not(missing(birthdt));
             quit;
          %end;

          %if NOT(&birthdt_var) %then     /* If BIRTHDT values are all missing then grab AGE variables from DEMO for updating input dataset */
          %do;
             proc sql noprint;
                select NAME into :age_vars separated by ' '
                   from dictionary.columns 
                   where libname = 'WORK' AND
                         memname = "%upcase(&prefix.demo)" AND
                         memtype = 'DATA' AND
                         upcase(name) in ('AGE','AGEMO','AGEWK','AGEDY');
             quit;

             %if %nrbquote(&age_vars) ne %then     /* Found at least 1 AGE variable so add those variables to the input dataset */
             %do;

                proc sort data=%unquote(&prefix.demo) out=&prefix._demo(keep=studyid subjid &age_vars) nodupkey;
                   by studyid subjid;
                run;
                proc sort data=&prefix._temp&i out=&prefix.agedsetin;
                   by studyid subjid;
                run;

                data &prefix._temp%eval(&i+1);
                   merge &prefix.agedsetin(in=A) &prefix._demo;
                   by studyid subjid;
                   if A;
                   %if %sysfunc(indexw(%upcase(&age_vars), AGE)) %then     /* Set expected variable name from Demo AGE variables */
                      &domaincode.AGE=AGE;;
                   %if %sysfunc(indexw(%upcase(&age_vars), AGEMO)) %then
                      &domaincode.AGEMO=AGEMO;;
                   %if %sysfunc(indexw(%upcase(&age_vars), AGEWK)) %then
                      &domaincode.AGEWK=AGEWK;;
                   %if %sysfunc(indexw(%upcase(&age_vars), AGEDY)) %then
                      &domaincode.AGEDY=AGEDY;;
                run;
          
                %let i=%eval(&i+1);
                %put %str(RTN)OTE: &sysmacroname: BIRTHDT is missing so variable(s) &age_vars from DEMODSET(=&demodset) will be added to the output dataset.;
             %end; 

             %else %do;  /* If no BIRTHDT and AGE variables exist then update input dataset by setting derive AGE variables to missing */
               %put %str(RTN)OTE: &sysmacroname: BIRTHDT is missing from DEMODSET(=&demodset) and no AGE variables exist so derive AGE variables set to missing.;
               data &prefix._temp%eval(&i+1);
                  set &prefix._temp&i;
                  %if %sysfunc(indexw(&noderivevars, &domaincode.AGE)) eq 0 %then
                  %do;
                     &domaincode.AGE=.;
                  %end;
                  %if %sysfunc(indexw(&noderivevars, &domaincode.AGEMO)) eq 0 %then
                  %do;
                     &domaincode.AGEMO=.;
                  %end;
                  %if %sysfunc(indexw(&noderivevars, &domaincode.AGEWK)) eq 0 %then
                  %do;
                     &domaincode.AGEWK=.;
                  %end;
                  %if %sysfunc(indexw(&noderivevars, &domaincode.AGEDY)) eq 0 %then
                  %do;
                     &domaincode.AGEDY=.;
                  %end;
               run;
               %let i=%eval(&i+1);
             %end;

          %end; /* No BIRTHDT variable exists or all values are missing */
 
          %else %do;  /* else BIRTHDT does exist */             

          /* Obtain birth date of subject from the &DEMODSET dataset. */
             proc sort data=&prefix.demo(keep=studyid subjid birthdt) out=&prefix._agedemo;
                 by studyid subjid;
             run;
 
             proc sort data=&prefix._temp&i out=&prefix.agedsetin;
                by studyid subjid;
             run;

             data &prefix._temp%eval(&i+1);
                merge &prefix.agedsetin(in=A) &prefix._agedemo(rename=(birthdt=_birthdt));
                by studyid subjid;
                drop _birthdt;

                if A;

                if &datevar. ne . and _birthdt ne . then
                do;
                   %if %sysfunc(indexw(&noderivevars,&domaincode.AGE)) eq 0 %then
                  %do;
                      &domaincode.AGE=intck('year',_birthdt,&datevar.) -
                                  ( month(&datevar.) lt month(_birthdt) or
                                  (month(&datevar.) eq month(_birthdt) and 
                                   day(&datevar.) lt day(_birthdt)) );
                  %end;

                   %if %sysfunc(indexw(&noderivevars,&domaincode.AGEMO)) eq 0 %then
                   %do;
                       &domaincode.AGEMO = (year(&datevar.) - year(_birthdt)) * 12
                                 + (month(&datevar.)-month(_birthdt)-1)
                                + (day(&datevar.) ge day(_birthdt) );
                   %end;

                   %if %sysfunc(indexw(&noderivevars,&domaincode.AGEWK)) eq 0 %then
                   %do;
                       &domaincode.AGEWK = int((&datevar. - _birthdt)/7);
                   %end;

                   %if %sysfunc(indexw(&noderivevars,&domaincode.AGEDY)) eq 0 %then
                   %do;
                       &domaincode.AGEDY = &datevar. - _birthdt;
                   %end;
                end;
             run;
          
             %let i=%eval(&i+1);
          %end;  /* ELSE DO */

       %end; /* %if %nrbquote(&datevar) ne */

       %else %do;
          data &prefix._temp%eval(&i+1);
             set &prefix._temp&i;
             %if %sysfunc(indexw(&noderivevars, &domaincode.AGE)) eq 0 %then
             %do;
                &domaincode.AGE=.;
             %end;
             %if %sysfunc(indexw(&noderivevars, &domaincode.AGEMO)) eq 0 %then
             %do;
                &domaincode.AGEMO=.;
             %end;
             %if %sysfunc(indexw(&noderivevars, &domaincode.AGEWK)) eq 0 %then
             %do;
                &domaincode.AGEWK=.;
             %end;
             %if %sysfunc(indexw(&noderivevars, &domaincode.AGEDY)) eq 0 %then
             %do;
                &domaincode.AGEDY=.;
             %end;
          run;
          %let i=%eval(&i+1);
       %end; /* if %nrbquote(&datevar) ne %else */
       
   %end; /* %if %nrbquote(&datevar) ne */          

   /*
   / Begin to derive other variables for specific domain.
   /----------------------------------------------------------------------------*/

   /*
   / Derivation of ADVERSE EVENT variables.
   / Derived variables: AEDURC AEONGO AETRTST AETRTSTC AEPTR1ST AEPTR1SC
   /                    AETRT1ST AETRT1SC
   /----------------------------------------------------------------------------*/

   %if &domaincode eq AE %then
   %do;

       data &prefix._temp%eval(&i+1);
            set &prefix._temp&i;

            /* AEDURC: Duration of event in character */
            %if %sysfunc(indexw(&noderivevars, AEDURC)) eq 0 %then
            %do;
               length aedurc $ 20;
               if aedur ne . then aedurc=trim(left(put(aedur, 8.))) || lowcase(substr(left("&durationunits"), 1, 1));
            %end;

            /* AEONGO: Ongoing adverse event */
            %if %sysfunc(indexw(&noderivevars, AEONGO)) eq 0 %then
            %do;
               if aeoutcd in ('2','3') then aeongo='Y';
               else aeongo='N';
            %end;
       run;

       %let i = %eval(&i + 1);

       /* AETRTST and AETRTSTC: Time from last dose to start of event */

       %if %sysfunc(indexw(&noderivevars, AETRTST)) eq 0 %then
       %do;
           %let notexistvars=%tu_chkvarsexist(&prefix._temp&i, AEONLDSH AEONLDSM);

           %if %qscan(&notexistvars, 2, %str( )) eq %then
           %do;
               /* Time to onset variables exist */
               data &prefix._temp%eval(&i+1);
                  set &prefix._temp&i;
                  length aetrtstc $ 20;
                  aetrtst = .;

                  %if %qupcase(&notexistvars) ne AEONLDSH %then
                  %do;
                     if aeonldsh ne . then aetrtst = aeonldsh/24;
                  %end;

                  %if %qupcase(&notexistvars) ne AEONLDSM %then
                  %do;
                     if aeonldsm ne . then aetrtst = sum(aetrtst, aeonldsm/(24*60));
                  %end;
                  
                  aetrtst=floor(aetrtst) + 1;

                  if aetrtst ne . then aetrtstc = trim(left(put(aetrtst, 8.))) || "d";
               run;

               %let noderivevars=&noderivevars AETRTST;
               %let i = %eval(&i + 1);

            %end;
        %end;
        
        %let expdataset=&exposuredset;

        %if ( %sysfunc(indexw(&noderivevars, AETRTST)) eq 0 ) or ( %sysfunc(indexw(&noderivevars, AETRT1ST)) eq 0 ) %then
        %do;
           %if %nrbquote(&exposuredset) eq %then
           %do;
              %put %str(RTW)ARNING: &sysmacroname: Can not derive AETRTST and/or AETRT1ST because parameter EXPOSUREDSET is blank.;
              %let noderivevars=&noderivevars AETRT1ST AETRTST;
           %end;
           %else %if %sysfunc(exist(%qscan(&exposuredset, 1, %str(%() ))) le 0 %then
           %do;
              %put %str(RTW)ARNING: &sysmacroname: Can not derive AETRTST and/or AETRT1ST because data set EXPOSUREDSET (=&exposuredset) does not exist.;
              %let noderivevars=&noderivevars AETRT1ST AETRTST;
           %end;
           %else %do;
              data &prefix.exposure;
                 set %unquote(&exposuredset);
              run;
              %let expdataset=&prefix.exposure;           
           %end;
        %end;

        /* YW002: Added the time in derivation of AETRTST */     
        %if %sysfunc(indexw(&noderivevars, AETRTST)) eq 0 %then
        %do;
        
           /* YW009: if exendt does not exist, or has no non-missing values, use exstdt */
           %let exendt=exendt;        
           %if %tu_chkvarsexist(&expdataset, &exendt) ne %then %let exendt=exstdt;        
           %let loopi=0;
      
           proc sql noprint;
              select count(&exendt) into :loopi
              from &expdataset
              where not missing(&exendt)
              ;
           quit;
                  
           %if &loopi eq 0 %then %let exendt=exstdt;  
           
           %let timevar=;
                           
           %if %tu_chkvarsexist(&expdataset, exsttm) eq %then 
           %do;
              %if %tu_chkvarsexist(&prefix._temp&i, aesttm) eq %then %let timevar=exsttm;
           %end;
           
           /* derive last treatment start date and end date from &exposure data set */
           proc sort data=&expdataset(keep=studyid subjid exstdt &exendt &timevar)
                     out=&prefix._expo nodupkey;
              by studyid subjid descending exstdt 
                 %if %nrbquote(&timevar) ne %then descending exsttm;;
              where exstdt ne .;
           run;

           /* Keep start and end date of dose from previous record */
           /* Create date range for each dose */
           data &prefix._expo_range;
              set &prefix._expo;
              by studyid subjid descending exstdt
                 %if %nrbquote(&timevar) ne %then descending exsttm;;                 
              format _hi date9.;                            
              %if %nrbquote(&timevar) ne %then 
              %do;
                 format _hitime time5.;
                 _hitime=lag1(exsttm);
                 _hi = lag1(exstdt);
                 
                 if missing(_hitime) then _hitime='00:00'T;                 
                 if _hitime eq '00:00'T then _hi=_hi - 1;
          
                 _hitime = _hitime - 1;
              %end;
              %else %do;
                 _hi=lag1(exstdt) - 1;  
              %end;

              if first.subjid then do;
                 _hi=max(&exendt, exstdt) + 10000;
              end;
           run;
           
           /* AE start date matched up with dose date range.    */
           /* Time from last dose to start of event calculated. */
           proc sql noprint;
              create table &prefix._temp%eval(&i+1) as
              select a.*, a.aestdt - b.&exendt + 1 as aetrtst
              from &prefix._temp&i as a left join
                  &prefix._expo_range as b
              on  a.studyid  eq  b.studyid
              and a.subjid   eq  b.subjid
              %if %nrbquote(&timevar) ne %then 
              %do;
                 and ( ( a.aestdt gt b.exstdt ) or (( a.aestdt eq b.exstdt ) and ( a.aesttm ge b.exsttm  )) )
                 and ( ( a.aestdt lt b._hi    ) or (( a.aestdt eq b._hi    ) and ( a.aesttm le b._hitime )) )      
              %end;
              %else %do;
                 and a.aestdt ge b.exstdt
                 and a.aestdt le b._hi
              %end;
              ;
           quit;
           %let i = %eval(&i + 1);

           /* If AE start date before dose end date then resulting */
           /* zero or negative AETRTST reassigned to value of 1.   */
           data &prefix._temp%eval(&i+1);
                set &prefix._temp&i;
                length aetrtstc $ 20;
                if . lt aetrtst lt 1 then aetrtst=1;
                if aetrtst ne . then aetrtstc = trim(left(put(aetrtst, 8.))) || "d";
           run;

           %let i = %eval(&i + 1);

       %end; /* Derive AETRTST and AETRTSTC */

       /* AETRT1ST and AETRT1SC: Time from first dose to start of event */

       %if %sysfunc(indexw(&noderivevars, AETRT1ST)) eq 0 %then
       %do;

          /* Exposure dataset exists */
          proc sort data=&expdataset(keep=studyid subjid exstdt) out=&prefix._expo nodupkey;
             by studyid subjid exstdt;
          run;

          data &prefix._expo_subj;
             set &prefix._expo;
             where exstdt ne .;
             by studyid subjid exstdt;
             if first.subjid;
          run;

          proc sql noprint;
             create table &prefix._temp%eval(&i+1) as
             select a.*, a.aestdt-b.exstdt+1 as aetrt1st
             from &prefix._temp&i as a left join
                  &prefix._expo_subj as b
             on  a.studyid  eq  b.studyid
             and a.subjid   eq  b.subjid
             and a.aestdt   ge b.exstdt;
          quit;

          %let i = %eval(&i + 1);

          data &prefix._temp%eval(&i+1);
             set &prefix._temp&i;
             length aetrt1sc $ 20;
             if aetrt1st ne . then aetrt1sc = trim(left(put(aetrt1st, 8.))) || "d";
          run;
          
          %let i = %eval(&i + 1);

       %end; /* Derive AETRT1ST and AETRT1SC */
       
       /* AEPTR1ST and AEPTR1SC: Time from pd 1st dose to start of event */
       %if %sysfunc(indexw(&noderivevars, AEPTR1ST)) eq 0 %then
       %do;
          %if %tu_chkvarsexist(&prefix._temp&i, PERTSTDT) eq %then
          %do;
             data &prefix._temp%eval(&i+1);
                  set &prefix._temp&i;
                  length aeptr1sc $ 20;
                  if aestdt ge pertstdt then
                     aeptr1st=aestdt - pertstdt + 1;
                  else 
                     aeptr1st=.;
                  if aeptr1st ne . then aeptr1sc = trim(left(put(aeptr1st, 8.))) || "d";
             run;
             
             %let i = %eval(&i + 1);
        %end;
          %else %do;          
             %put %str(RTW)ARNING: &sysmacroname: Can not derive AEPTR1ST/AEPTR1SC, because PERTSTDT does not exist.;
          %end;
       %end; /* Derive AEPTR1ST and AEPTR1SC */
          
   %end; /* DOMAINCODE=AE */

   /*
   / Derivation of EXPOSURE variables.
   / Derived variables: DOSETOT DOSECUM RANDNUM EXDURCUM
   /----------------------------------------------------------------------------*/

   %else %if &domaincode eq EX %then
   %do;
       /* DOSETOT: Total daily dose */
       %if %sysfunc(indexw(&noderivevars, DOSETOT)) eq 0 %then
       %do;
           %if &durationunits eq DAYS %then
           %do;
                data &prefix._temp%eval(&i+1);
                  set &prefix._temp&i;
                  if dosefrcd eq 'OD' then dosetot=dose;
                  else if dosefrcd eq 'BID' then dosetot=dose*2;
                  else if dosefrcd eq 'TID' then dosetot=dose*3;
                  else if dosefrcd eq 'QID' then dosetot=dose*4;
                  else dosetot=.;
                run;
                %let i = %eval(&i + 1);
           %end;
           %else %if &durationunits eq HOURS %then
           %do;
                data &prefix._temp%eval(&i+1);
                  set &prefix._temp&i;
                  if dosefrcd eq 'OD' then dosetot=dose;
                  else if dosefrcd eq 'BID' then dosetot=dose*2;
                  else if dosefrcd eq 'TID' then dosetot=dose*3;
                  else if dosefrcd eq 'QID' then dosetot=dose*4;
                  else dosetot=.;
                run;
                %let i = %eval(&i + 1);
           %end;
       %end;

       /* DOSECUM: Cumulative dose */
       %if %sysfunc(indexw(&noderivevars,DOSECUM)) eq 0 %then
       %do;
           %if &durationunits eq DAYS %then
           %do;
                data &prefix._temp%eval(&i+1);
                  set &prefix._temp&i;
                  if ( dosetot ne . ) and ( exdur ne . ) then dosecum=dosetot*exdur;
                  else dosecum=.;
                run;
                %let i = %eval(&i + 1);
           %end;
           %else %if &durationunits eq HOURS %then
           %do;
                data &prefix._temp%eval(&i+1);
                  set &prefix._temp&i;
                  if ( dosetot ne . ) and ( exdur ne . ) then dosecum=dosetot*exdur/24;
                  else dosecum=.;
                run;
                %let i = %eval(&i + 1);
           %end;
       %end;

       /* RANDNUM: Randomization number from SI RAND dataset */
       %if %sysfunc(indexw(&noderivevars,RANDUM)) eq 0 %then
       %do;
          %let loopi=0;
                              
          %if %nrbquote(&randdset) eq %then
          %do;          
              %put %str(RTW)ARNING: &sysmacroname: The parameter RANDDSET is blank.;
              %put %str(RTW)ARNING: &sysmacroname: The derived variable RANDNUM has been set to missing.;
              %let loopi=1;
          %end;
          %else %if %sysfunc(exist(%qscan(&randdset, 1, %str(%() ))) le 0 %then
          %do;          
              %put %str(RTW)ARNING: &sysmacroname: The dataset RANDDSET(=&randdset) does not exist.;
              %put %str(RTW)ARNING: &sysmacroname: The derived variable RANDNUM has been set to missing.;
              %let loopi=1;
          %end;
      
          %if &loopi eq 0 %then
          %do;
              data &prefix.rand;
                 set %unquote(&randdset);
              run;
              
              proc sql noprint;
                   create table &prefix._temp%eval(&i+1) as
                   select a.*, b.randnum
                   from &prefix._temp&i as a left join &prefix.rand as b
                   on  a.studyid  eq  b.studyid
                   and a.subjid   eq  b.subjid;
              quit;
              %let i = %eval(&i + 1);
          %end;
          %else %if %tu_chkvarsexist(&prefix._temp&i, randnum) ne %then
          %do;
              data &prefix._temp%eval(&i+1);
                set &prefix._temp&i;
                randnum=.;
              run;
              %let i = %eval(&i + 1);
          %end; 
       %end;  /* %if %sysfunc(indexw(&noderivevars,RANDUM)) eq 0 */
       
       /* EXDURCUM: Cumulative duration */
       %if %sysfunc(indexw(&noderivevars, EXDURCUM)) eq 0 %then
       %do;
          %if %tu_chkvarsexist(&prefix._temp&i, ACTTRT EXDUR) eq %then 
          %do;
             proc summary data=&prefix._temp&i ;
                class studyid subjid acttrt /missing;
                types studyid*subjid*acttrt;
                var exdur;
                output out=&prefix._excum(drop=_type_ _freq_) sum=exdurcum;
             run;
             
             proc sort data=&prefix._temp&i out=&prefix._temp%eval(&i + 1);
                by studyid subjid acttrt;
             run;
             
             %let i = %eval(&i + 1);
             
             data &prefix._temp%eval(&i + 1);
                merge &prefix._temp&i 
                      &prefix._excum;
                by studyid subjid acttrt;
             run;
             
             %let i = %eval(&i + 1);
             
          %end;
          %else %do;          
             %put %str(RTW)ARNING: &sysmacroname: Variable ACTTRT/EXDUR is not in data set &prefix._temp&i. Variable EXDURCUM can not be derived.;
          %end;
       
       %end;

   %end; /* DOMAINCODE=EX */

   /*
   / Derivation of ELIG variables.
   / Derived variables: IECRTNUM
   /----------------------------------------------------------------------------*/

   %else %if &domaincode eq IE %then
   %do;

       %if %sysfunc(indexw(&noderivevars,IECRTNUM)) eq 0 %then
       %do;
            /* If there is more than one visit, show the criteria as         */
            /* visit || '_' || criteria. For example, if there are two       */
            /* records:                                                      */
            /*    visitnum=10  iecrtnum=1                                    */
            /*    visitnum=12  iecrtnum=1                                    */
            /* then modify IECRTNUM to:                                      */
            /*    visitnum=10  iecrtnum=10_1                                 */
            /*    visitnum=12  iecrtnum=12_1                                 */
            /* If there is only a single visit then do not add visit to      */
            /* the iecrtnum. For example, if there are two records:          */
            /*    visitnum=10  iecrtnum=1                                    */
            /*    visitnum=10  iecrtnum=3                                    */
            /* then do not modify IECRTNUM:                                  */
            /*    visitnum=10  iecrtnum=1                                    */
            /*    visitnum=10  iecrtnum=3                                    */

            /* Determine the number of visits.                               */

            proc sql noprint;
                 select count(unique(visitnum)) into :numvisit
                 from &prefix._temp&i;
            quit;

            /* Modify IECRTNUM if multiple VISITs on dataset  */
            data &prefix._temp%eval(&i+1);
                 set &prefix._temp&i;

                 %if &numvisit gt 1 %then
                 %do;
                     iecrtnum=trim(left(visitnum)) || '_' || trim(left(iecrtnum));
                 %end;
                 %else
                 %do;
                     iecrtnum=trim(left(iecrtnum));
                 %end;
            run;

            %let i = %eval(&i + 1);
       %end;

   %end; /* DOMAINCODE=IE */

   /*
   / Derivation of VITALS variables.
   / Derived variables: VSBMI
   /----------------------------------------------------------------------------*/

   %else %if &domaincode eq VS %then
   %do;

       /* VSBMI: Body/Mass Index. */
       %if %sysfunc(indexw(&noderivevars,VSBMI)) eq 0 %then
       %do;
          %if %tu_chkvarsexist(&prefix._temp&i, HEIGHT WEIGHT) eq %then
          %do;
              data &prefix._temp%eval(&i+1);
                set &prefix._temp&i;
                if height ne . and weight ne . then vsbmi=weight/((height/100)**2);
              run;

              %let i = %eval(&i + 1);
          %end;
          %else
          %do;
             %put %str(RTN)OTE: &sysmacroname: The derivation of VSBMI requires both HEIGHT and WEIGHT to be available.;
          %end;
       %end;

   %end; /* &domaincode eq VS */
      
   /*   
   / Derivation of RU variables.
   / Derived variables: RUTRTST RUTRT1ST RUSTRTPT
   /----------------------------------------------------------------------------*/
   
   %else %if &domaincode eq RU %then 
   %do;

    /* 
    /  BA001 - Check if the Exposure start and end date exist in RUCAM dataset, if true then process
    /--------------------------------------------------------------------------------------------------*/
      %if %tu_chkvarsexist(&prefix._temp&i, exstdt exendt) eq %then %do; 

        /* RUTRTST: Time from last dose to start of event */
      
         %if ( %sysfunc(indexw(&noderivevars, RUTRTST)) eq 0 ) or 
             ( %sysfunc(indexw(&noderivevars, RUSTRTPT)) eq 0 ) %then
         %do;
      
            /*  if exendt does not exist, or has no non-missing values, use exstdt */
            %let exendt=exendt;        
            %if %tu_chkvarsexist(&prefix._temp&i, &exendt) ne %then %let exendt=exstdt;        
            %let loopi=0;
      
            proc sql noprint;
               select count(&exendt) into :loopi
               from &prefix._temp&i
               where not missing(&exendt)
               ;
            quit;
                
            %if &loopi eq 0 %then %let exendt=exstdt;        
                  
            %let timevar=;
                         
            %if %tu_chkvarsexist(&prefix._temp&i, exsttm) eq %then 
            %do;
               %if %tu_chkvarsexist(&prefix._temp&i, aesttm) eq %then %let timevar=exsttm;
            %end;
         
         %end; /* %if ( %sysfunc(indexw(&noderivevars, RUTRTST)) eq 0 ) or ( %sysfunc(indexw(&noderivevars, RUSTRTPT)) eq 0 ) */

         /* RUTRTST */ 
         %if ( %sysfunc(indexw(&noderivevars, RUTRTST)) eq 0 ) %then 
         %do;
      
            /* derive last treatment start date and end date from &exposure data set */
            proc sort data=&prefix._temp&i(keep=studyid subjid exstdt &exendt &timevar)
                      out=&prefix._expo nodupkey;
               by studyid subjid descending exstdt 
                  %if %nrbquote(&timevar) ne %then descending exsttm;;
               where exstdt ne .;
            run;
      
            /* Keep start and end date of dose from previous record */
            /* Create date range for each dose */
            data &prefix._expo_range;
               set &prefix._expo;
               by studyid subjid descending exstdt
                  %if %nrbquote(&timevar) ne %then descending exsttm;;                 
               format _hi date9.;                            
               %if %nrbquote(&timevar) ne %then 
               %do;
                  format _hitime time5.;
                  _hitime=lag1(exsttm);
                  _hi = lag1(exstdt);
               
                  if missing(_hitime) then _hitime='00:00'T;                 
                  if _hitime eq '00:00'T then _hi=_hi - 1;
        
                  _hitime = _hitime - 1;
               %end;
               %else %do;
                  _hi=lag1(exstdt) - 1;  
               %end;

               if first.subjid then do;
                  _hi=max(&exendt, exstdt) + 10000;
               end;
            run;

            /* RU start date matched up with dose date range.    */
            /* Time from last dose to start of event calculated. */
            proc sql noprint;
               create table &prefix._temp%eval(&i+1) as
               select a.*, a.rudt - b.&exendt + 1 as RUTRTST
               from &prefix._temp&i as a left join
                   &prefix._expo_range as b
               on  a.studyid  eq  b.studyid
               and a.subjid   eq  b.subjid
               and a.rudt ge b.exstdt
               and a.rudt le b._hi
               ;
            quit;
            %let i = %eval(&i + 1);

            /* If RU start date before dose end date then resulting */
            /* zero or negative AETRTST reassigned to value of 1.   */
            data &prefix._temp%eval(&i+1);
                 set &prefix._temp&i;
                 if . lt rutrtst lt 1 then rutrtst=1;
            run;

            %let i = %eval(&i + 1);

         %end; /* Derive RUTRTST */
      
         /* RUSTRTPT */
         %if %sysfunc(indexw(&noderivevars, RUSTRTPT)) eq 0 %then 
         %do;
            %let exendt=exendt;
         
            %if %tu_chkvarsexist(&prefix._temp&i, &exendt) ne %then %let exendt=exstdt;
         
            %let loopi=0;
                                
            proc sql noprint;
               select count(&exendt) into :loopi
               from &&prefix._temp&i             
               where not missing(&exendt);
            quit;
         
            %if &loopi eq 0 %then %let exendt=exstdt;                                     
      
            proc sort data=&prefix._temp&i;
               by studyid subjid rudt;
            run;

            data &prefix._temp%eval(&i+1);
               set &prefix._temp&i;
               by studyid subjid;
               length RUSTRTPT $6;
               if missing(&exendt) then RUSTRTPT='';
               else if rudt gt &exendt then RUSTRTPT='AFTER';
               else if rudt le &exendt then RUSTRTPT='BEFORE';
               else RUSTRTPT='';        
            run;

            %let i = %eval(&i + 1);               
         %end; /* %if %sysfunc(indexw(&noderivevars, RUSTRTPT)) eq 0 */    
      
         /* RUTRT1ST: Time from first dose to start of event */

         %if %sysfunc(indexw(&noderivevars, RUTRT1ST)) eq 0 %then
         %do;

            data &prefix._temp%eval(&i+1);
               set &prefix._temp&i;
               if NOT(missing(exstdt)) AND (rudt ge exstdt) then RUTRT1ST = rudt - exstdt + 1;
            run;

            %let i = %eval(&i + 1);

         %end; /* Derive RUTRT1ST */

         %if %sysfunc(indexw(&noderivevars, RUSTRTPT)) eq 0 OR 
             %sysfunc(indexw(&noderivevars, RUTRT1ST)) eq 0    %then 
         %do;
            data &prefix._merge_rucam_ds;
               set &prefix._temp&i(keep=studyid subjid rutestcd %tu_chkvarsexist(&prefix._temp&i,RUSTRTPT RUTRT1ST, Y));
               where rutestcd = 'LVEVOC';
               drop rutestcd;
            run;

            %let _rucam_var_list=;
            proc sql noprint;
               select name into :_rucam_var_list separated by ','
                  from dictionary.columns
                  where upcase(name) in ('RUSTRTPT','RUTRT1ST') and
                        libname = 'WORK' and
                        memname = "%upcase(&prefix._temp&i)" and
                        memtype = 'DATA';

               alter table &prefix._temp&i drop &_rucam_var_list;
 
               create table &prefix._temp%eval(&i+1) as
                  select a.*, b.&_rucam_var_list
                     from &prefix._temp&i a, &prefix._merge_rucam_ds b
                     where a.studyid = b.studyid and
                           a.subjid = b.subjid;
            quit;
            %let i = %eval(&i + 1);

         %end;

      %end;

   /* 
   / BA001 - ELSE the Exposure start date and end date do not exist in RUCAM use the Exposure dataset 
   /         exstdt and exendt variables for processing
   /-----------------------------------------------------------------------------------------------------------------*/

      %else %do;  
         %let expdataset=&exposuredset;

         %if ( %sysfunc(indexw(&noderivevars, RUTRTST))  eq 0 ) or 
             ( %sysfunc(indexw(&noderivevars, RUTRT1ST)) eq 0 ) or
             ( %sysfunc(indexw(&noderivevars, RUSTRTPT)) eq 0 ) %then
         %do;
            %if %nrbquote(&exposuredset) eq %then
            %do;
               %put %str(RTW)ARNING: &sysmacroname: Can not derive RUSTRTPT, RUTRTST and/or RUTRT1ST because parameter EXPOSUREDSET is blank.;
               %let noderivevars=&noderivevars RUSTRTPT RUTRT1ST RUTRTST;
            %end;
            %else %if %sysfunc(exist(%qscan(&exposuredset, 1, %str(%() ))) le 0 %then
            %do;
               %put %str(RTW)ARNING: &sysmacroname: Can not derive RUSTRTPT, RUTRTST and/or RUTRT1ST because data set EXPOSUREDSET (=&exposuredset) does not exist.;
               %let noderivevars=&noderivevars RUSTRTPT RUTRT1ST RUTRTST;
            %end;
            %else %do;
               data &prefix.exposure;
                  set %unquote(&exposuredset);
               run;
               %let expdataset=&prefix.exposure;           
            %end;
         %end; /* One of RUTRTST, RUTRT1ST and RUSTRTPT is not in &NODERIVEVARS */

        /* RUTRTST: Time from last dose to start of event */
      
         %if ( %sysfunc(indexw(&noderivevars, RUTRTST)) eq 0 ) or 
             ( %sysfunc(indexw(&noderivevars, RUSTRTPT)) eq 0 ) %then
         %do;
      
            /*  if exendt does not exist, or has no non-missing values, use exstdt */
            %let exendt=exendt;        
            %if %tu_chkvarsexist(&expdataset, &exendt) ne %then %let exendt=exstdt;        
            %let loopi=0;
      
            proc sql noprint;
               select count(&exendt) into :loopi
               from &expdataset
               where not missing(&exendt)
               ;
            quit;
                
            %if &loopi eq 0 %then %let exendt=exstdt;        
                  
            %let timevar=;
                         
            %if %tu_chkvarsexist(&expdataset, exsttm) eq %then 
            %do;
               %if %tu_chkvarsexist(&prefix._temp&i, aesttm) eq %then %let timevar=exsttm;
            %end;
         
         %end; /* %if ( %sysfunc(indexw(&noderivevars, RUTRTST)) eq 0 ) or ( %sysfunc(indexw(&noderivevars, RUSTRTPT)) eq 0 ) */

         /* RUTRTST */ 
         %if ( %sysfunc(indexw(&noderivevars, RUTRTST)) eq 0 ) %then 
         %do;
      
            /* derive last treatment start date and end date from &exposure data set */
            proc sort data=&expdataset(keep=studyid subjid exstdt &exendt &timevar)
                      out=&prefix._expo nodupkey;
               by studyid subjid descending exstdt 
                  %if %nrbquote(&timevar) ne %then descending exsttm;;
               where exstdt ne .;
            run;
      
            /* Keep start and end date of dose from previous record */
            /* Create date range for each dose */
            data &prefix._expo_range;
               set &prefix._expo;
               by studyid subjid descending exstdt
                  %if %nrbquote(&timevar) ne %then descending exsttm;;                 
               format _hi date9.;                            
               %if %nrbquote(&timevar) ne %then 
               %do;
                  format _hitime time5.;
                  _hitime=lag1(exsttm);
                  _hi = lag1(exstdt);
               
                  if missing(_hitime) then _hitime='00:00'T;                 
                  if _hitime eq '00:00'T then _hi=_hi - 1;
        
                  _hitime = _hitime - 1;
               %end;
               %else %do;
                  _hi=lag1(exstdt) - 1;  
               %end;

               if first.subjid then do;
                  _hi=max(&exendt, exstdt) + 10000;
               end;
            run;

            /* RU start date matched up with dose date range.    */
            /* Time from last dose to start of event calculated. */
            proc sql noprint;
               create table &prefix._temp%eval(&i+1) as
               select a.*, a.rudt - b.&exendt + 1 as rutrtst
               from &prefix._temp&i as a left join
                   &prefix._expo_range as b
               on  a.studyid  eq  b.studyid
               and a.subjid   eq  b.subjid
               and a.rudt ge b.exstdt
               and a.rudt le b._hi
               ;
            quit;
            %let i = %eval(&i + 1);

            /* If RU start date before dose end date then resulting */
            /* zero or negative AETRTST reassigned to value of 1.   */
            data &prefix._temp%eval(&i+1);
                 set &prefix._temp&i;
                 if . lt rutrtst lt 1 then rutrtst=1;
            run;

            %let i = %eval(&i + 1);

         %end; /* Derive RUTRTST */
      
         /* RUSTRTPT */
         %if %sysfunc(indexw(&noderivevars, RUSTRTPT)) eq 0 %then 
         %do;         
            /* YW009: if exendt does not exist, or has no non-missing values, use exstdt */
            %let exendt=exendt;
         
            %if %tu_chkvarsexist(&expdataset, &exendt) ne %then %let exendt=exstdt;
         
            %let loopi=0;
                                
            proc sql noprint;
               select count(&exendt) into :loopi
               from &expdataset             
               where not missing(&exendt);
            quit;
         
            %if &loopi eq 0 %then %let exendt=exstdt;                                     
      
            /* derive last treatment end date from &exposure data set */
            proc sort data=&expdataset(keep=studyid subjid &exendt)
                      out=&prefix._expo nodupkey;
               by studyid subjid &exendt;
               where not missing(&exendt);
            run;
         
            data &prefix._expo;
               set &prefix._expo;
               by studyid subjid &exendt;
               if last.subjid;
            run;
         
            proc sort data=&prefix._temp&i;
               by studyid subjid rudt;
            run;

            data &prefix._temp%eval(&i+1);
               merge &prefix._temp&i(in=__in1__) &prefix._expo;
               by studyid subjid;
               drop &exendt;
               length RUSTRTPT $6;
               if missing(&exendt) then rustrtpt='';
               else if rudt gt &exendt then rustrtpt='AFTER';
               else if rudt le &exendt then rustrtpt='BEFORE';
               else rustrtpt='';        
               if __in1__ then output;  
            run;

            %let i = %eval(&i + 1);               
         %end; /* %if %sysfunc(indexw(&noderivevars, RUSTRTPT)) eq 0 */    
      
         /* RUTRT1ST: Time from first dose to start of event */

         %if %sysfunc(indexw(&noderivevars, RUTRT1ST)) eq 0 %then
         %do;

            /* Exposure dataset exists */
            proc sort data=&expdataset(keep=studyid subjid exstdt) out=&prefix._expo nodupkey;
               by studyid subjid exstdt;
            run;

            data &prefix._expo_subj;
               set &prefix._expo;
               where exstdt ne .;
               by studyid subjid exstdt;
               if first.subjid;
            run;

            proc sql noprint;
               create table &prefix._temp%eval(&i+1) as
               select a.*, a.rudt-b.exstdt+1 as rutrt1st
               from &prefix._temp&i as a left join
                    &prefix._expo_subj as b
               on  a.studyid  eq  b.studyid
               and a.subjid   eq  b.subjid
               and a.rudt ge b.exstdt;
            quit;

            %let i = %eval(&i + 1);

         %end; /* Derive RUTRT1ST */
 
      %end;  /* END processing for RUTRTST RUSTRTPT RUTRT1ST */
     
      /* RUPTR1ST: Time from pd 1st dose to start of event */
      %if %sysfunc(indexw(&noderivevars, RUPTR1ST)) eq 0 %then
      %do;
         %if %tu_chkvarsexist(&prefix._temp&i, PERTSTDT) eq %then
         %do;
            data &prefix._temp%eval(&i+1);
                 set &prefix._temp&i;
                 if rudt ge pertstdt then
                    ruptr1st=rudt - pertstdt + 1;
                 else 
                    ruptr1st=.;
            run;
            
            %let i = %eval(&i + 1);
         %end;
         %else %do;          
            %put %str(RTW)ARNING: &sysmacroname: Can not derive RUPTR1ST, because PERTSTDT does not exist.;
         %end;
         
      %end; /* Derive RUPTR1ST */
  
   %end; /* %if  &domaincode eq RU */
   
   /*
   / YW002: Get a list of variables, which should not be derived, in current 
   / data set
   /----------------------------------------------------------------------------*/
   
   %let listvars=;
          
   proc contents data=&dsetin out=&prefix._conta(keep=name) noprint;
   run;
   
   proc contents data=&prefix._temp&i out=&prefix._contb(keep=name) noprint;
   run;
                     
   data _null_;
      set &prefix._conta(in=a) 
          &prefix._contb(in=b) end=end;                  
      length listvars varas $32761;
      retain listvars '' varas '';
      
      name=upcase(name);                                                           
      if a then varas=trim(varas)||' '||left(name);
      if b and ( indexw(varas, name) eq 0 ) then 
      do;
         if ( indexw(symget('derivevars'),  name) eq 0 ) or 
          ( ( indexw(symget('derivevars'),  name) gt 0 ) and
            ( indexw(symget('noderivevars'),name) gt 0 ) )
         then do;
            listvars=trim(listvars)||' '||left(name);
         end;
      end; /* end-if on b and ( indexw(varas, upcase(name)) eq 0 ) */
            
      if end then      
         call symput('listvars', trim(left(listvars)));
   run;                             
                                               
   /*
   / create output data set.
   /----------------------------------------------------------------------------*/
      
   data &dsetout;
      set &prefix._temp&i;      
      %if %nrbquote(&listvars) ne %then
      %do;
         drop %unquote(&listvars); 
      %end;      
   run;    
      
   /*
   / Delete temporary datasets used in this macro.
   /----------------------------------------------------------------------------*/

   %tu_tidyup(
      rmdset =&prefix:,
      glbmac =NONE
      );

%endmac:

%mend tu_derive;

