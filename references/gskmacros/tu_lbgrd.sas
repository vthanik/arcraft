/*******************************************************************************
|
| Macro Name:      tu_lbgrd
|
| Macro Version:   3
|
| SAS Version:     9.1.3
|
| Created By:      Eric Simms
|
| Date:            28-Sep-2006
|
| Macro Purpose:   Assignment of National Cancer Institute Common Terminology 
|                  Criteria (Toxicity) Grade (NCI-CTC) to lab data.
|                  Originally written for TOPOTECAN:SK104864 (Author: Mary Katherine Dee),
|                  this macro was modified extensively for use in HARP environment by Mike 
|                  Gunshenan, Diane Foose, Joe Novotny.
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME               DESCRIPTION                            REQ/OPT  DEFAULT
| --------------     -----------------------------------    -------  ---------------
| DSETIN             Specifies the existing SAS dataset     REQ      (Blank)
|                    for which CTCAE Grading needs to be
|                    done.
|                    Valid values: valid dataset name     
|
| DSETOUT            Specifies the name of the output       REQ      (Blank)
|                    dataset to be created.
|                    Valid values: valid dataset name
|
| CTCDSET            Specifies the SI dataset which         OPT      dmdata.lbgrade 
|                    contains the CTCAE range information.
|
| CTCVER             Version of CTCAE to use.               OPT      CTCAE03.00
|
| DSPLAN             Specifies the path and file name of    OPT      (Blank)
|                    the HARP A&R dataset metadata. This 
|                    will define the format to use in  
|                    decoding LBTOXCD into LBTOX.
|                    NOTE: this parameter is only used
|                          by tu_decode and all checks
|                          will be done within tu_decode.
|
| FORMATNAMESDSET    Specifies the name of a dataset which  OPT      (Blank)
|                    contains VAR_NM (a variable name of a 
|                    code) and FORMAT_NM (the name of a 
|                    format to produce the decode). This
|                    can be used in place of the DSPLAN
|                    parameter.
|                    NOTE: this parameter is only used
|                          by tu_decode and all checks
|                          will be done within tu_decode.
|
| --------------  -----------------------------------  -------  ---------------
|
| The macro references the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETIN            Req      Parameter specified dataset
| &CTCDSET           Req      Parameter specified dataset
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
|(@) tu_chkvarsexist
|(@) tu_decode
|(@) tu_nobs
|(@) tu_putglobals
|(@) tu_tidyup
|
| Example:
|    %tu_lbgrd(
|         dsetin  = _lab1,
|         dsetout = _lab2,
|         dsplan  = &dsplan,
|         formatnamesdset = &formatnamesdset
|         );
|
|******************************************************************************
| Change Log
|
| Modified By:              Diane Foose and Yongwei Wang
|                           The code is modified by Diane Foose and reviewed
|                           by Yongwei Wang.
| Date of Modification:     11 May 2007
| New version/draft number: 2/1
| Modification ID:          DF001
| Reason For Modification:  To correct for cases where grade was not being assigned
|                           to differentials with an original unit of Percent, 
|                           because Normal Ranges are not converted to standard units
|                           and our code was expecting these NRs to be there. 
|                           Based on change request HRT0162
|
| Modified By:              Diane Foose 
| Date of Modification:     14 May 2010
| New version/draft number: 3/1
| Modification ID:          DF002
| Reason For Modification:  a) To add new grading rules for increased Hemoglobin 
|                           N2 - values based on upper limit of normal
|                           b) Adding LBGRDVER variable to the output dataset
|--------------------------------------------------------------------------------
|
*******************************************************************************/

%macro tu_lbgrd (
     dsetin   = ,                  /* Input dataset name */
     dsetout  = ,                  /* Output dataset name */
     ctcdset  = DMDATA.LBGRADE,    /* Normal range dataset name */
     ctcver   = CTCAE03.00,        /* CTCAE version */
     dsplan   =  ,                 /* Path and filename of tab-delimited file containing HARP A&R dataset plan */
     formatnamesdset =             /* Format names dataset name */
        );

 /*
 / Echo parameter values and global macro variables to the log.
 /----------------------------------------------------------------------------*/

 %local MacroVersion;
 %let MacroVersion = 3;
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals()

 /*
 / PARAMETER VALIDATION
 /----------------------------------------------------------------------------*/

 %let dsetin   = %nrbquote(&dsetin);
 %let dsetout  = %nrbquote(&dsetout);
 %let ctcdset  = %nrbquote(&ctcdset);
 %let ctcver   = %nrbquote(&ctcver);

 /*
 / Check for required parameters.
 /----------------------------------------------------------------------------*/

 %if &dsetin eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter DSETIN is required.;
    %let g_abort=1;
 %end;

 %if &dsetout eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter DSETOUT is required.;
    %let g_abort=1;
 %end;

 %if &ctcdset eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter CTCDSET is required.;
    %let g_abort=1;
 %end;

 %if &ctcver eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter CTCVER is required.;
    %let g_abort=1;
 %end;

 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end;

 /*
 / Check for existing datasets.
 /----------------------------------------------------------------------------*/

 %if %sysfunc(exist(&dsetin)) eq 0 %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The input dataset DSETIN (&dsetin) does not exist.;
    %let g_abort=1;
 %end;

 %if %sysfunc(exist(&ctcdset)) eq 0 %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The reference dataset CTCDSET (&ctcdset) does not exist.;
    %let g_abort=1;
 %end;

 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end;

 /*
 / Check that input dataset has the expected fields.
 /----------------------------------------------------------------------------*/

 %local reqvars;
 %let reqvars=%tu_chkvarsexist(&dsetin, LBTESTCD LBSTUNIT LBSTRESN LBSTNRLO LBSTNRHI);
 %if &reqvars ne %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The input dataset DSETIN (&dsetin) does not have the following;
    %put %str(RTE)RROR: &sysmacroname: required variables: &reqvars;
    %let g_abort=1;
 %end;

 /*
 / Check that input dataset does not have LBTOXCD, LBTOX, LBTOXTX variables.
 / According to Dataset Manager, the SI LAB dataset may have LBTOXCD. This  
 / should only happen for HIV studies and not for oncology studies; this macro
 / assigns oncology grades only. As a precaution, we also check for the
 / existence of LBTOX and LBTOXTX even though they should not be on the 
 / SI LAB dataset at any time. 
 /----------------------------------------------------------------------------*/

 %let not_allowed_var1=%tu_chkvarsexist(&dsetin, LBTOXCD); 
 %let not_allowed_var2=%tu_chkvarsexist(&dsetin, LBTOX); 
 %let not_allowed_var3=%tu_chkvarsexist(&dsetin, LBTOXTX); 

 %local not_allowed_vars;
 %if &not_allowed_var1 eq  %then %let not_allowed_vars=LBTOXCD;
 %if &not_allowed_var2 eq  %then %let not_allowed_vars=&not_allowed_vars LBTOX;
 %if &not_allowed_var3 eq  %then %let not_allowed_vars=&not_allowed_vars LBTOXTX;
 %if &not_allowed_vars ne  %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The input dataset DSETIN (&dsetin) must not have the variables LBTOXCD,;
    %put %str(RTE)RROR: &sysmacroname: LBTOX, LBTOXTX. The following non-permitted variables were on the dataset:;
    %put %str(RTE)RROR: &sysmacroname: &not_allowed_vars;
    %let g_abort=1;
 %end;

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
    %put %str(RTN)OTE: &sysmacroname: The input dataset name (&dsetin) is the same as the;
    %put %str(RTN)OTE: &sysmacroname: output dataset name (&dsetout).;
 %end;

 /*
 / NORMAL PROCESSING
 /----------------------------------------------------------------------------*/

 %local prefix;
 %let prefix = _lbgrd;   /* Root name for temporary work datasets */

 /* Write RTNOTE specifying the number of records on the input dataset. */

 %local numobs;
 %let numobs=%tu_nobs(&dsetin);
 %put %str(RTN)OTE: &sysmacroname: Number of records in the input dataset DSETIN (&DSETIN);
 %put %str(RTN)OTE: &sysmacroname: before tox grading: %trim(%left(&numobs));

 /* Get only those records for the desired version from CTCDSET. */

 data &prefix._lbctcgrd;
   set &ctcdset(drop=lbgrdseq where=(lbgrdver="&ctcver"));
 run;

 /* If no records are found for the specified version, write  */
 /* RTERROR message to the log and abort.                     */

 %if %tu_nobs(&prefix._lbctcgrd) le 0 %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: No records found with LBGRDVER=&ctcver in CTCDSET (&CTCDSET);
    %let g_abort=1;
    %tu_abort();
 %end; /* No records found for the desired version from CTCDSET. */

/*
/ In order to keep track of which records have and have not been assigned grades,
/ we create a simple record id which can be used to split up the graded and non-graded
/ records.
/ This record id will also be used during the LBTOXCD/LBTOX decode logic.
/--------------------------------------------------------------------------------------*/

data &prefix._lab_all;
  set &dsetin;
  _recid_=_n_;
run;

/*
/ Separate lab records that can be tox graded from those that cannot because:
/ a) they do not have an entry for LBTESTCD in the CTCDSET dataset.
/ b) they have missing LBSTRESN values.
/ c) they have an entry for LBTESTCD in the CTCDSET dataset, but the LBSTUNIT does not match.
/--------------------------------------------------------------------------------------*/

/*
/ a) they do not have an entry for LBTESTCD in the CTCDSET dataset.
/--------------------------------------------------------------------------------------*/

 /* Prepare for merge. */
 proc sort data=&prefix._lab_all;
   by lbtestcd lbstunit;
 run;

 /* Get unique values of LBTESTCD in the CTCDSET dataset. */
 proc sort data=&prefix._lbctcgrd(keep=lbtestcd) out=&prefix._lbtestcd nodupkey;
   by lbtestcd;
 run;

 /* Find match/nonMatch LBTESTCD. */
 data &prefix._unmatch_lbtestcd &prefix._match_lbtestcd;
   merge &prefix._lab_all(in=A) &prefix._lbtestcd(in=B);
   by lbtestcd;

   if A and B then output &prefix._match_lbtestcd;
   else if A then output &prefix._unmatch_lbtestcd;
 run;

 /*
 / b) they have missing LBSTRESN values.
 /--------------------------------------------------------------------------------------*/

 data &prefix._missing_lbstresn &prefix._non_missing_lbstresn;
   set &prefix._match_lbtestcd;
   if lbstresn=. then output &prefix._missing_lbstresn;
   else output &prefix._non_missing_lbstresn;
 run;

 /*
 / c) they have an entry for LBTESTCD in the CTCDSET dataset, but the LBSTUNIT does not match.
 /--------------------------------------------------------------------------------------*/

 /* Get unique combinations of LBTESTCD, LBSTUNIT in the CTCDSET dataset. */
 proc sort data=&prefix._lbctcgrd(keep=lbtestcd lbstunit) out=&prefix._lbtestcd_lbstunit nodupkey;
   by lbtestcd lbstunit;
 run;

 /* Find match/nonMatch LBSTUNIT. */
 data &prefix._unmatch_lbstunit &prefix._match_lbstunit;
   merge &prefix._non_missing_lbstresn(in=A) &prefix._lbtestcd_lbstunit(in=B);
   by lbtestcd lbstunit;

   if A and B then output &prefix._match_lbstunit;
   else if A then output &prefix._unmatch_lbstunit;
 run;

 /* If records were found with matching LBTESTCD but non-matching LBSTUNIT, write messages to the log. */

 %if %tu_nobs(&prefix._unmatch_lbstunit) ge 1 %then
 %do;
    proc sort data=&prefix._unmatch_lbstunit(keep=lbtestcd lbstunit) out=&prefix._msgs_unmatched nodupkey;
      by lbtestcd lbstunit;
    run;

    data _null_;
      set &prefix._msgs_unmatched;
      put "RTW" "ARNING: &sysmacroname: LBTESTCD=" lbtestcd " LBSTUNIT=" lbstunit " combination in DSETIN (&DSETIN)";
      put "RTW" "ARNING: &sysmacroname: not found in CTCDSET (&CTCDSET)";
    run;
 %end;

 /*
 /     Perform Toxicity calculations.
 /     LBALGCD:  C : assign grade according to the criteria low and high limits.
 /               N1: use LAB low normal value as the high end.
 /               L2: use LAB low normal value as the lower end.
 /               H1: use LAB high normal value as the lower end.
 /               H2: use LAB high value as the inclusive high end.
 /               N3: multiply LBSTNRHI by criteria low and high limits to obtain the low and high ends.
 /               L4: Assign grade according to the criteria low and high limits. Reassign as
 /                   grade 0 if LBSTRESN >= LBSTNRLO.
 /               H4: Assign grade according to the criteria low and high limits. Reassign as
 /                   grade 0 if LBSTRESN <= LBSTNRHI.
 /               N2: Add LBSTNRHI to criteria low and high limits to obtain the low and high ends.
 /               LH: use LAB low and high normal limits for both ends.
 /     LBGRIECD: 1:  Inclusive on low end, exclusive on high end.
 /               2:  Exclusive on low end, inclusive on high end.
 /               3:  Inclusive on both ends.
 /               4:  Exclusive on both ends.
 /---------------------------------------------------------------------------------*/

 /*
 / Perform first round of toxicity grading.
 / DF002.B Adding LBGRDVER variable to the output dataset
 /-------------------------------------------------------------------------*/

 proc sql noprint;
   create table &prefix._round_1 as
      select A.*, B.lbtoxcd, B.lbtoxtx, B.lbgrdver
      from &prefix._match_lbstunit A,
           &prefix._lbctcgrd B
      where (B.lbalgcd in('C','L4','H4') and
            A.lbtestcd = B.lbtestcd and
            A.lbstunit = B.lbstunit and
            (B.lbgrdlo = . or 
                  (B.lbgrdlo ne . and (A.lbstresn gt B.lbgrdlo or (A.lbstresn = B.lbgrdlo and B.lbgriecd in('1','3')))))
             and
            (B.lbgrdhi = . or 
                  (B.lbgrdhi ne . and (A.lbstresn lt B.lbgrdhi or (A.lbstresn = B.lbgrdhi and B.lbgriecd in('2','3')))))
             );
 quit;

 /*
 / Create a dataset with records yet to be graded.
 /-------------------------------------------------------------------------*/

 proc sql noprint;
  create table &prefix._not_round_1 as
    select * from &prefix._match_lbstunit
    where _recid_ not in(select _recid_ from &prefix._round_1);
 quit;

 /*
 / Perform second round of toxicity grading.
 / DF002.A Add new grading rules for increased Hemoglobin 
 /         N2 - values based on upper limit of normal
 / DF002.B Adding LBGRDVER variable to the output dataset
 /-------------------------------------------------------------------------*/

 proc sql;
   create table &prefix._round_2 as 
      select A.*, B.lbtoxcd, B.lbtoxtx, B.lbgrdver
      from &prefix._not_round_1 A,
           &prefix._lbctcgrd B
      where A.lbtestcd = B.lbtestcd and
            A.lbstunit = B.lbstunit and
            (  (B.lbalgcd = 'N1' and
                  (A.lbstresn gt B.lbgrdlo or (A.lbstresn = B.lbgrdlo and B.lbgriecd in('1','3'))) and
                  (A.lbstresn lt A.lbstnrlo or (A.lbstresn = A.lbstnrlo and B.lbgriecd in('2','3')))
                ) or

               (B.lbalgcd = 'L2' and
                A.lbstnrlo ne . and (A.lbstresn gt A.lbstnrlo or (A.lbstresn = A.lbstnrlo and B.lbgriecd in('1','3')))
                ) or

               (B.lbalgcd = 'H1' and
                A.lbstnrhi ne . and
                  (A.lbstresn gt A.lbstnrhi or (A.lbstresn = A.lbstnrhi and B.lbgriecd in('1','3')))
                ) or

               (B.lbalgcd = 'H2' and
                  (A.lbstresn lt A.lbstnrhi or (A.lbstresn = A.lbstnrhi and B.lbgriecd in('2','3')))
                ) or

               (B.lbalgcd = 'N3' and
                (B.lbgrdlo = . or (B.lbgrdlo ne . and
                               A.lbstnrhi ne . and
                               (A.lbstresn gt (B.lbgrdlo*A.lbstnrhi) 
                                  or (A.lbstresn = (B.lbgrdlo*A.lbstnrhi) and B.lbgriecd in('1','3')))
                                 )
                 ) and
                (B.lbgrdhi = . or 
                    (B.lbgrdhi ne . and A.lbstnrhi ne . and
                        (A.lbstresn lt (B.lbgrdhi*A.lbstnrhi) or
                          (A.lbstresn = (B.lbgrdhi*A.lbstnrhi) and B.lbgriecd in('2','3'))
                         )
                     )
                 )
                ) or

               (B.lbalgcd = 'N2' and
                (B.lbgrdlo = . or (B.lbgrdlo ne . and
                               A.lbstnrhi ne . and
                               (A.lbstresn gt (B.lbgrdlo+A.lbstnrhi) 
                                  or (A.lbstresn = (B.lbgrdlo+A.lbstnrhi) and B.lbgriecd in('1','3')))
                                 )
                 ) and
                (B.lbgrdhi = . or 
                    (B.lbgrdhi ne . and A.lbstnrhi ne . and
                        (A.lbstresn lt (B.lbgrdhi+A.lbstnrhi) or
                          (A.lbstresn = (B.lbgrdhi+A.lbstnrhi) and B.lbgriecd in('2','3'))
                         )
                     )
                 )
                )
             );
 quit;

 /*
 / Create a dataset with records yet to be graded.
 /-------------------------------------------------------------------------*/

 proc sql noprint;
  create table &prefix._not_round_2 as
    select * from &prefix._not_round_1
    where _recid_ not in(select _recid_ from &prefix._round_2);
 quit;


 /*
 / Perform third round of toxicity grading.
 / DF002.B Adding LBGRDVER variable to the output dataset
 /-------------------------------------------------------------------*/

 proc sql;
   create table &prefix._round_3 as
      select A.*, B.lbtoxcd, B.lbtoxtx, B.lbgrdver
      from &prefix._not_round_2 A,
           &prefix._lbctcgrd B
      where A.lbtestcd = B.lbtestcd and 
            A.lbstunit = B.lbstunit and
            ((B.lbalgcd = 'L4' and A.lbstresn ge A.lbstnrlo and A.lbstnrlo ne .) or
             (B.lbalgcd = 'LH' and A.lbstnrlo ne . and A.lbstnrhi ne . and (A.lbstnrlo le A.lbstresn le A.lbstnrhi)) or
             (B.lbalgcd = 'H4' and A.lbstresn le A.lbstnrhi and A.lbstnrhi ne .));
 quit;

 /*
 / Create a dataset with records yet to be graded.
 /-------------------------------------------------------------------------*/

 proc sql noprint;
  create table &prefix._not_round_3 as
    select * from &prefix._not_round_2
    where _recid_ not in(select _recid_ from &prefix._round_3);
 quit;

 /*
 / Perform fourth round of toxicity grading.
 / DF002.B Adding LBGRDVER variable to the output dataset
 /-------------------------------------------------------------------------*/

 proc sql;
   create table &prefix._round_4 as
      select A.*, B.lbtoxcd, B.lbtoxtx, B.lbgrdver
      from &prefix._not_round_3 A,
           &prefix._lbctcgrd B
      where A.lbtestcd = B.lbtestcd and
            A.lbstunit = B.lbstunit and
            SUBSTR(A.lbtestcd,1,4) in ('NEUT','LYMP') and
            (  (B.lbalgcd = 'N1' and
                  (A.lbstresn gt B.lbgrdlo or (A.lbstresn = B.lbgrdlo and B.lbgriecd in('1','3'))) and
                  (A.lborresn lt A.lbornrlo or (A.lborresn = A.lbornrlo and B.lbgriecd in('2','3')))
                ) or

               (B.lbalgcd = 'L2' and
                A.lbornrlo ne . and (A.lborresn gt A.lbornrlo or (A.lborresn = A.lbornrlo and B.lbgriecd in('1','3')))
                ) 
            );
 quit;

 /*
 / Create a dataset with records yet to be graded.
 /-------------------------------------------------------------------------*/

 proc sql noprint;
  create table &prefix._not_round_4 as
    select * from &prefix._not_round_3
    where _recid_ not in(select _recid_ from &prefix._round_4);
 quit;

 /*
 / Concatenate all tox graded datasets together along
 / with the datasets containing data not able to be tox graded.
 / Derive the LBTOX value.
 /---------------------------------------------------------------------*/

 data &prefix._concat_data;
  set &prefix._round_1 &prefix._round_2 &prefix._round_3 &prefix._round_4 &prefix._not_round_4
      &prefix._unmatch_lbtestcd &prefix._unmatch_lbstunit &prefix._missing_lbstresn;
 run;

 /*
 / Derive the LBTOX value.
 / There is no need to run the entire dataset through tu_decode, which
 / would re-derive all of the decoded variables. We only need the decode
 / of LBTOXCD placed into LBTOX, so we split up the dataset such that
 / only that decode will be processed by tu_decode and then combine the
 / data again.
 /---------------------------------------------------------------------*/

 data &prefix._decode_data;
   set &prefix._concat_data(keep=_recid_ lbtoxcd);
 run;

 %tu_decode(dsetin=&prefix._decode_data,
           dsetout=&prefix._decode_data,
           dsplan=&dsplan,
           formatnamesdset=&formatnamesdset);

 proc sort data=&prefix._decode_data;
   by _recid_;
 run;

 proc sort data=&prefix._concat_data;
   by _recid_;
 run;

 data &dsetout(drop=_recid_ label="Output Data Set from TU_LBGRD");
   merge &prefix._concat_data &prefix._decode_data;
   by _recid_;
   label lbtox = "Grade";
 run;

 /* Write RTNOTE specifying the number of records on the output dataset. */

 %let numobs=%tu_nobs(&dsetout);
 %put %str(RTN)OTE: &sysmacroname: Number of records in the output dataset DSETOUT (&DSETOUT);
 %put %str(RTN)OTE: &sysmacroname: after tox grading: %trim(%left(&numobs));

 /*
 / Delete temporary datasets used in this macro.
 /----------------------------------------------------------------------------*/

 %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tu_lbgrd;
