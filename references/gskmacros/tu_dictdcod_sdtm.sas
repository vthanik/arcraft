/*******************************************************************************
| 
| Macro Name:      tu_dictdcod_sdtm
|
| Macro Version/Build:   1/1
|
| SAS Version:     9.1
|
| Created By:     Ashwin V based on tu_dictdcod created by Mark Luff / Eric Simms
|
| Date:            4 July 2011
|
| Macro Purpose:   MEDDRA and GSKDRUG dictionary decoding
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME               DESCRIPTION                            REQ/OPT  DEFAULT
| -----------------  -------------------------------------  -------  ----------
| DSETIN             Specifies the dataset for which        REQ      (Blank)
|                    MedDRA/GSKDrug variables are to be 
|                    added.
|                    Valid values:  valid dataset name
|
| DSETOUT            Specifies the name of the output       REQ      (Blank)
|                    dataset to be created.
|                    Valid values: Valid dataset name
|
| CMANALYN           If set to Y, then additional           REQ      N
|                    processing will be done to produce
|                    an A&R-structured CMANAL dataset   
|                    instead of an A&R-structured CONMEDS 
|                    dataset for output.      
|                    Valid values:  Y or N
|
| -----------------  -------------------------------------  -------  ----------
|
| The macro references the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETIN            Req      Parameter specified dataset
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
|(@) tu_putglobals
|(@) tu_abort
|(@) tu_chkvarsexist
|(@) tu_tidyup
|
| Example:
|    %tu_dictdcod(
|         dsetin            = _ae1,
|         dsetout           = _ae2
|         );
|
|******************************************************************************
| Change Log
|
| Modified By: Eric Simms
| Date of Modification: 08Nov04
| New version/draft number:  1/2
| Modification ID: ems001
| Reason For Modification: Final ELSE block to handle input datasets without 
|                          one of AELLTCD, CMDRGCOL, MHLLTCD, SPLLTCD variables 
|                          on the dataset.
|
| Modified By:             Yongwei Wang
| Date of Modification:    03Apr05
| New version/draft number:1/3
| Modification ID:         YW001
| Reason For Modification: Added derivation of DISPLAY1/DISPLAY2
|
| Modified By:             Yongwei Wang
| Date of Modification:    13Nov07
| New version/draft number:2/1
| Modification ID:         YW002
| Reason For Modification: Added derivation of DISPLAY4
|
| Modified By:             Khilit Shah
| Date of Modification:    28Sep09
| New version/draft number:3/1
| Modification ID:         KS001
| Reason For Modification: Based on Change Request HRT0229
|                          Two additional base variables to be derived
|                          1) CMBASECD =  first 6 characters of the CMCOMPCD
|                          2) CMBASE = CMBASED || 01  then linked with CMCOMP
|
*******************************************************************************/
%macro tu_dictdcod_sdtm (
     dsetin            = ,      /* Input dataset name */
     dsetout           = ,      /* Output dataset name */
     cmanalyn          = N      /* CMANAL flag Y/N */
        );

 /*
 / Echo parameter values and global macro variables to the log.
 /----------------------------------------------------------------------------*/

 %local MacroVersion;
 %let MacroVersion = 1;
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals() 

 /*
 / PARAMETER VALIDATION
 /----------------------------------------------------------------------------*/

 %let dsetin            = %nrbquote(&dsetin);
 %let dsetout           = %nrbquote(&dsetout);

 %if %nrbquote(&cmanalyn) ne %then
    %let cmanalyn          = %nrbquote(%upcase(%substr(&cmanalyn, 1, 1)));
 %else
    %let cmanalyn          = %nrbquote(&cmanalyn);

 /*
 / Check for required parameters.
 /----------------------------------------------------------------------------*/

 %if &dsetin eq %then
 %do;
    %put %str(RTE)RROR: TU_DICTDCOD: The parameter DSETIN is required.;
    %let g_abort=1;
 %end;  /* end-if  Required parameter DSETIN not specified.  */

 %if &dsetout eq %then
 %do;
    %put %str(RTE)RROR: TU_DICTDCOD: The parameter DSETOUT is required.;
    %let g_abort=1;
 %end;  /* end-if  Required parameter DSETOUT not specified.  */

 %if &cmanalyn eq %then
 %do;
    %put %str(RTE)RROR: TU_DICTDCOD: The parameter CMANALYN is required.;
    %let g_abort=1;
 %end;  /* end-if  Required parameter CMANALYN not specified.  */

 /*
 / Check for existing datasets.
 /----------------------------------------------------------------------------*/

 %if %sysfunc(exist(&dsetin)) eq 0 %then
 %do;
    %put %str(RTE)RROR: TU_DICTDCOD: The dataset DSETIN(=&dsetin) does not exist.;
    %let g_abort=1;
 %end;  /*  end-if  Specified DSETIN parameter does not exist.  */

 /*
 / Check for valid parameter values.
 /----------------------------------------------------------------------------*/

 %if &cmanalyn ne Y and &cmanalyn ne N %then
 %do;
    %put %str(RTE)RROR: TU_DICTDCOD: CMANALYN should be either Y or N.;
    %let g_abort=1;
 %end;  /* end-if  Specified CMANALYN parameter is not valid.  */

 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end;

 /*
 / If the input dataset name is the same as the output dataset name,
 / write a note to the log.
 /----------------------------------------------------------------------------*/

 %if &dsetin eq &dsetout %then
 %do;
    %put %str(RTN)OTE: TU_DICTDCOD: The input dataset name (&dsetin) is the same as the output dataset name (&dsetout).;
 %end;  /* end-if  Specified DSET and DSETOUT parameters are the same.  */

 /* 
 /*
 / NORMAL PROCESSING
 /----------------------------------------------------------------------------*/

 %local prefix;
 %let prefix = _dictdcod;   /* Root name for temporary work datasets */

 /*
 / Create variables derived from MedDRA dictionary for Adverse Event data.
 /----------------------------------------------------------------------------*/

 data &prefix._existdsetin;
    if 0 then set %unquote(&dsetin);
 run;
 
 %if %tu_chkvarsexist(&prefix._existdsetin, aelltcd) eq  %then 
 %do;
    proc sql noprint;
         create table &prefix._meddra as
         select aelltcd, aellt, aeptcd, aept, aesoccd, aesoc, aehltcd, aehlt, aehlgtcd, aehlgt
         from diction.meddra
         where aelltcd in (select distinct aelltcd from &dsetin)
         and   aepathcd eq '1'
         and   aenc eq 'C';
    quit;

    proc sql noprint;
         create table &dsetout as
         select a.*
         %if %length(%tu_chkvarsexist(&dsetin,aellt)) ge 1 %then %do;
           , b.aellt
         %end;
        %if %length(%tu_chkvarsexist(&dsetin,aeptcd)) ge 1 %then %do;
         , b.aeptcd
        %end;
        %if %length(%tu_chkvarsexist(&dsetin,aept)) ge 1 %then %do;
        , b.aept
        %end;
        %if %length(%tu_chkvarsexist(&dsetin,aesoccd)) ge 1 %then %do;
        , b.aesoccd
        %end;
        %if %length(%tu_chkvarsexist(&dsetin,aesoc)) ge 1 %then %do;
        , b.aesoc
        %end;
        ,b.aehltcd, b.aehlt, b.aehlgtcd, b.aehlgt
         from &dsetin as a left join &prefix._meddra as b
         on a.aelltcd eq b.aelltcd;
    quit;
 %end;  /* end-if  Variable AELLTCD exist in user-specified dataset &DSETIN.  */

 /*
 / Create variables derived from GSKDRUG dictionary
 / for Concomitant Medications data.
 /----------------------------------------------------------------------------*/

 %else %if %tu_chkvarsexist(&prefix._existdsetin, cmdrgcol) eq  %then 
 %do;
    proc sql noprint;
         create table &prefix._gskdrug1 as
         select cmdrgcol, cmdecod, cmatccd, cmatc1
         from diction.gskdrug
         where cmdrgcol in (select distinct cmdrgcol from &dsetin)
         and   cmnc eq 'C'
         order by cmdrgcol, cmdecod, cmatccd;
    quit;

    data &prefix._gskdrug2;
         set &prefix._gskdrug1;
         by cmdrgcol cmdecod cmatccd;

         retain _count;

         /* Remove duplicates resulting from multiple ingredient drugs */
         if first.cmatccd;

         if first.cmdrgcol then _count=1;
                           else _count+1;

         length _name $ 9;
         _name = "cmatc"||trim(left(_count))||"_1";
    run;

    proc transpose data   = &prefix._gskdrug2
                   out    = &prefix._atccd (drop=_name_ _label_ rename=(cmdrgcol = _drgcol1))
                   prefix = cmatccd;
         by cmdrgcol;
         var cmatccd;
         id _count;
    run;

    proc transpose data = &prefix._gskdrug2
                   out  = &prefix._atc (drop=_name_ _label_ rename=(cmdrgcol = _drgcol2));
         by cmdrgcol cmdecod;
         var cmatc1;
         id _name;
    run;

    proc sql noprint;
         create table &prefix._conmeds(drop=_drgcol1) as
         select a.*, b.*
         from &dsetin as a left join &prefix._atccd as b
         on  a.cmdrgcol eq b._drgcol1;

         /* At this point we create the output dataset for CONMEDS, or do some */
         /* additional processing in order to create CMANAL.                   */

         %if &cmanalyn ne Y %then
         %do;
            create table &dsetout(drop=_drgcol2) as
         %end;
         %else
         %do;
            create table &prefix._cmanal1(drop=_drgcol2) as
         %end;
         select a.*, b.*
         from &prefix._conmeds as a left join &prefix._atc as b
         on  a.cmdrgcol eq b._drgcol2;
    quit;

    %if &cmanalyn eq Y %then
    %do;
         /*
         / Do additional processing in order to create CMANAL dataset.
         /----------------------------------------------------------------------------*/

         proc sql;
              /* Get Component and ATC codes from GSKDRUG dictionary corresponding to collection generic code. */
              create table &prefix._gskdrug3 as
              select cmdrgcol, cmcompcd, cmcomp, cmatccd,
                     cmatc1, cmatc2, cmatc3, cmatc4
              from diction.gskdrug
              where cmdrgcol in (select distinct cmdrgcol from &prefix._cmanal1)
              and   cmnc eq 'C'
              order by cmdrgcol, cmcompcd, cmatccd;
        
              /* Get a dictinct list of ATC codes for each single ingredient drug */
              create table &prefix._atcdrg1 as
              select distinct cmdrgcol, cmcompcd, cmcomp,
                              cmatccd, cmatc1, cmatc2, cmatc3, cmatc4,
                              0 as mulfl
              from &prefix._gskdrug3
              where cmdrgcol eq cmcompcd;
        
              /* Get a dictinct list of ATC codes for each multiple ingredient drug */
              create table &prefix._atcdrg2 as
              select distinct cmdrgcol, 'Multiple Ingredient' as cmcomp,
                              cmatccd, cmatc1, cmatc2, cmatc3, cmatc4,
                              1 as mulfl
              from &prefix._gskdrug3
              where cmdrgcol ne cmcompcd;
        
              /* Get a list of component codes for each multi-ingredient drug */
              create table &prefix._compdrg as
              select distinct cmdrgcol, cmcompcd, cmcomp
              from &prefix._gskdrug3
              where cmdrgcol ne cmcompcd;
        
              /* Get ATC codes from GSKDRUG dictionary corresponding to component codes for multi-ingredient drugs. */
              create table &prefix._compatc as
              select a.cmdrgcol, a.cmcompcd, a.cmcomp, b.cmatccd,
                     b.cmatc1, b.cmatc2, b.cmatc3, b.cmatc4,
                     1 as mulfl
              from &prefix._compdrg as a left join diction.gskdrug as b
              on  a.cmcompcd eq b.cmdrgcol
              and b.cmnc eq 'C'
              order by a.cmdrgcol, a.cmcompcd, b.cmatccd;
         quit;
        
         /* Get a list of all Component and ATC code combinations */
         data &prefix._allcomb;
              set &prefix._compatc &prefix._atcdrg1 &prefix._atcdrg2;
        
              /* Set MULATCFL for ATC codes relating to overall multi-ingredient drug. */
              if cmcompcd eq ' ' then mulatcfl=1;
                                 else mulatcfl=0;
         run;
         
         /* YW002: Add a unique variable to mark each record */                   
         data &prefix._cmanal1;
            set &prefix._cmanal1;
            __multiseq=_n_;
         run;
        
         proc sql;
              /* Merge Component and ATC code information onto medications dataset by collection generic code. */
              create table &prefix._cmanal2 as
              select a.*, b.cmcompcd, b.cmcomp, b.cmatccd,
                     b.cmatc1, b.cmatc2, b.cmatc3, b.cmatc4,
                     b.mulfl, b.mulatcfl
              from &prefix._cmanal1 as a left join &prefix._allcomb as b
              on a.cmdrgcol eq b.cmdrgcol;
         quit;
        
         proc sort data=&prefix._compdrg;
              by cmdrgcol cmcompcd;
         run;
        
         %local MAXL;
         %let MAXL=200;
        
         data &prefix._concat;
              set &prefix._compdrg;
              by cmdrgcol cmcompcd;
              retain _decod;
        
              if first.cmdrgcol then _decod=cmcomp;
              else do;
                   if (not last.cmdrgcol and (length(_decod) + length(cmcomp) + 1 lt &MAXL)) or 
                      (last.cmdrgcol and (length(_decod) + length(cmcomp) + 1 le &MAXL)) then
                   do;
                      _decod = trim(_decod) || '+' || cmcomp;
                   end;
                   else if length(_decod) lt &MAXL then 
                   do;
                      _decod = trim(_decod) || substr('+' || cmcomp,1,&MAXL-length(_decod));
                      _decod = substr(_decod,1,&MAXL-7)||'/+OTHER';
                   end;
              end;
        
              if last.cmdrgcol then output;
         run;
        
         proc sql;
              /* Merge concatenated ingredient information onto medications dataset by collection generic code. */
              create table &prefix._cmanal3 as
              select a.*, b._decod
              from &prefix._cmanal2 as a left join &prefix._concat as b
              on a.cmdrgcol eq b.cmdrgcol
              order by a.__multiseq;
         quit;
        
         /* Set collection generic term to concatenated ingredients for combo drug atc records. */
         /* YW002: Set DISPLAY4 to 1 for each __multiseq with DISPLAY2 equals 1 */
         data &prefix._cmanal4(drop=_decod  __multiseqflag);
              set &prefix._cmanal3;              
              by __multiseq;
              retain __multiseqflag;
              if first.__multiseq then __multiseqflag=1;
              if cmcompcd eq ' ' then cmdecod = _decod;
              
              /* YW001: Added derivation of DISPLAY1/DISPLAY2 */
              if MULATCFL ne 1 then DISPLAY1=1;
              else DISPLAY1=0;
              if MULATCFL eq MULFL then DISPLAY2=1;
              else DISPLAY2=0;    
                             
              if DISPLAY2 and __multiseqflag then 
              do;
                 DISPLAY4=1;
                 __multiseqflag=0;
              end;
              else DISPLAY4=0;              

              CMBASECD = substr(cmcompcd,1,6) ;
         run;

         /* KS001: Derive CMBASE and CMBASECD */
         PROC SQL ;
               create table &prefix._gskdrug_base as
               select distinct cmcompcd, substr(cmcompcd,1,6) as CMBASECD,  cmcomp as CMBASE
               from diction.gskdrug
               where index((LEFT(TRIM(reverse(cmcompcd)))),'10') = 1;
         QUIT ;

         PROC SQL ;
             create table &prefix._cmanal5 (drop = __multiseq) as
             select a.*, b.CMBASE
             from &prefix._cmanal4 as a left join &prefix._gskdrug_base as b
             ON a.cmbasecd = b.cmbasecd
             ORDER BY __multiseq  ;
         QUIT ;

         data  &dsetout;
           set &prefix._cmanal5 ;
           if cmbasecd NE . AND cmbase = '' then cmbase = "NO BASE SPECIFIED";
         run;


    %end; /* end-if Ends CMANAL processing when user-specified CMANALYN parameter equals 'Y'. */
 %end;   /* end-if Variable CMDRGCOL exists in user-specified DSETIN parameter.  */

 /*
 / Create variables derived from MedDRA dictionary for Medical History data.
 /----------------------------------------------------------------------------*/

 %else %if %tu_chkvarsexist(&prefix._existdsetin, mhlltcd) eq  %then 
 %do;
    proc sql noprint;
         create table &prefix._meddra as
         select aelltcd, aellt, aeptcd, aept, aesoccd, aesoc
         from diction.meddra
         where aelltcd in (select distinct mhlltcd from &dsetin)
         and   aepathcd eq '1'
         and   aenc eq 'C';
    quit;
  
    proc sql noprint;
         create table &dsetout as
         select a.*, b.aellt as mhllt, b.aeptcd as mhptcd, b.aept as mhpt, b.aesoccd as mhsoccd, aesoc as mhsoc
         from &dsetin as a left join &prefix._meddra as b
         on a.mhlltcd eq b.aelltcd;
    quit;
 %end; /* end-else Variable MHLLTCD exists in user-specified DSETIN parameter.  */

 /*
 / Create variables derived from MedDRA dictionary for Surgery data.
 /----------------------------------------------------------------------------*/

 %else %if %tu_chkvarsexist(&prefix._existdsetin, splltcd) eq  %then 
 %do;
    proc sql noprint;
         create table &prefix._meddra as
         select aelltcd, aellt, aeptcd, aept
         from diction.meddra
         where aelltcd in (select distinct splltcd from &dsetin)
         and   aepathcd eq '1'
         and   aenc eq 'C';
    quit;

    proc sql noprint;
         create table &dsetout as
         select a.*, b.aellt as spllt, b.aeptcd as spptcd, b.aept as sppt
         from &dsetin as a left join &prefix._meddra as b
         on a.splltcd eq b.aelltcd;
    quit;
 %end; /* end-else Variable SPLLTCD exists in user-specified DSETIN parameter.  */

 /* ems001
 /  Final ELSE block to handle input datasets without
 /  one of AELLTCD, CMDRGCOL, MHLLTCD, SPLLTCD variables
 /  on the dataset.
 /----------------------------------------------------------------------------*/
 
 %else
 %do;
    %put %str(RTN)OTE: TU_DICTDCOD: The input dataset (&DSETIN) does not have one of AELLTCD, CMDRGCOL, MHLLTCD, SPLLTCD variables.;
    %put %str(RTN)OTE: TU_DICTDCOD: The output dataset (&DSETOUT) is set to the input dataset (&DSETIN) as is.;

    data &dsetout;
      set &dsetin;
    run;
 %end;  /* end-else none of AELLTCD, CMDRGCOL, MHLLTCD, SPLLTCD variables found on input dataset */

 /*
 / Delete temporary datasets used in this macro.
 /----------------------------------------------------------------------------*/

 %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tu_dictdcod_sdtm;

