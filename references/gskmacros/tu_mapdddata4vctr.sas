/*------------------------------------------------------------------------------
| Macro Name:         tu_mapdddata4vctr
|                     
| Macro Version:      1 build 1
|                     
| SAS Version:        9.3
|                     
| Created By:         Anthony J Cooper
|                     
| Date:               26-May-2016
|                     
| Macro Purpose:      To create input datasets for the XML utility macro from 
|                     the input data display datasets provided.
|                     
| Macro Design:       Procedure style.
|
| Input Parameters:
|
| Name                Description                                  Default
| -----------------------------------------------------------------------------------
|
| VCTRCR8USXMLYN      Controls whether the tu_cr8xml4vctr utility  Y
|                     macro creates a US results format XML file
|                     Valid values: Y or N
|
| VCTRCR8EUXMLYN      Controls whether the tu_cr8xml4vctr utility  Y
|                     macro creates a EU results format XML file
|                     Valid values: Y or N
|
| VCTRSTUDYID         Specifies the VCTR study identifier which    %upcase(&g_study_id)
|                     may be different to the HARP study
|                     identifier
|
| VCTRTRTDESCRFMT     SAS format used to format the treatment      (Blank)
|                     code value to the long treatment description
|                     Valid values: Valid SAS format name or blank
|
| BASECHARYN          Controls whether Baseline Characteristics    Y
|                     XML files are created
|                     Valid values: Y or N
|
| BCMEASURE1          Each baseline measure definition shall       %nrstr(dsetin=dddata.dm1
|                     contain details of the input Data Display    (where=(tt_segorder=1)), 
|                     dataset name, variable names and other       measureTitle='Age continuous', 
|                     metadata needed to construct the Baseline    measureUnits='Years',
|                     Characteristics input datasets for the       statslist=MEAN STD,
|                     tu_cr8xml4vctr macro                         tt_decodevarname=tt_decode1, 
|                                                                  acrossColVarPrefix=tt_result,
|                                                                  totalIDvalue=9999)
|
| BCMEASURE2          Same as BCMEASURE1                           %nrstr(dsetin=dddata.dm1
|                                                                  (where=(tt_segorder=2 and
|                                                                  tt_decode1 ne 'n')),
|                                                                  measureTitle = 'Gender, male/female',
|                                                                  measureUnits='Participants',
|                                                                  tt_codevarname=tt_code1,
|                                                                  tt_decodevarname=tt_decode1,
|                                                                  acrossColVarPrefix=tt_result,
|                                                                  totalIDvalue=9999)
|
| BCMEASURE3          Same as BCMEASURE1                           %nrstr(dsetin=dddata.dm1
|                                                                  (where=(tt_segorder=4 and 
|                                                                  tt_decode1 ne 'n')),
|                                                                  measureTitle="Race/Ethnicity, Customized",
|                                                                  measureUnits='Participants',
|                                                                  tt_codevarname=tt_code1,
|                                                                  tt_decodevarname=tt_decode1,
|                                                                  acrossColVarPrefix=tt_result,
|                                                                  totalIDvalue=9999)
|
| BCMEASURE4-         Same as BCMEASURE1                           (Blank)
| BCMEASURE20
|
| BCMEASUREDESCRFMT   SAS format used to format the baseline       (Blank)
|                     measure number to the long baseline measure 
|                     description field
|                     Valid values: Valid SAS format name or blank
|
| BCGROUPSDSETOUT     Name of baseline characteristics reporting   (Blank)
|                     groups dataset used to create the XML file.
|                     Valid values: Blank or A valid SAS dataset
|                     name
|
| BCDESCRDSETOUT      Name of baseline characteristics measure     (Blank)
|                     descriptions dataset used to create the
|                     XML file.
|                     Valid values: Blank or A valid SAS dataset
|                     name
|
| BCRESULTSDSETOUT    Name of baseline characteristics measure     (Blank)
|                     results dataset used to create the XML file.
|                     Valid values: Blank or A valid SAS dataset
|                     name
|
| PARTFLOWYN          Controls whether Participant Flow            Y
|                     XML files are created
|                     Valid values: Y or N
|
| PFMSTONE            The parameter definition shall contain       %nrstr(dsetin=dddata.es1a
|                     details of the input Data Display dataset    (where=(tt_segorder=1)), 
|                     name, variable names and other metadata      tt_decodevarname=tt_decode1,
|                     needed to construct the Participant Flow     acrossColVarPrefix=tt_ac)
|                     Milestones input dataset for the 
|                     tu_cr8xml4vctr utility macro
|
| PFWITHDRAW          The parameter definition shall contain       %nrstr(dsetin=dddata.es1a
|                     details of the input Data Display dataset    (where=(tt_segorder=2 and
|                     name, variable names and other metadata      left(tt_decode1) eq tt_decode1)),
|                     needed to construct the Participant Flow     tt_decodevarname=tt_decode1,
|                     Withdrawal Reasons input dataset for the     acrossColVarPrefix=tt_ac)
|                     tu_cr8xml4vctr utility macro
|
| PFAEOUTCOME         The parameter definition shall contain       %nrstr(dsetin=dddata.es1a
|                     details of the input Data Display dataset    (where=(tt_segorder=4)),
|                     name, variable names and other metadata      tt_decodevarname=tt_decode1,
|                     needed to  to determine the outcome status   acrossColVarPrefix=tt_ac)
|                     (fatal or non-fatal) of adverse events       
|                     leading to withdrawal
|
| PFPERIODTITLEVARS   Contains variables that will be used to      (Blank)
|                     populate the periodID and periodTitle
|                     variables in the XML file.
|                     When the parameter is blank, periodID will
|                     be set to 1 and periodTitle to "Overall
|                     Study".
|                     When the parameter is not blank, periodID
|                     will be populated using the first variable
|                     and periodTitle using the second variable.
|                     Valid values: Blank or a code/decode pair
|                     of variables
|
| PFWDREASFMT         SAS format used to format the collected      $wdrawmap.
|                     withdrawal reasons to standard reasons
|                     expected by the tu_cr8xml4vctr utility
|                     macro.
|                     Valid values: Valid SAS format name or blank
|
| PFTRTRTTYPEFMT      SAS format used to format the treatment      (Blank)
|                     code value to the treatment type description.
|                     Treatment type description values are
|                     expected to be one of "EXPERIMENTAL",
|                     "ACTIVECOMPARATOR", "PLACEBOCOMPARATOR",
|                     "NOINTERVENTION" or "OTHER: treatment type
|                     description text"
|                     Valid values: Valid SAS format name or blank
|
| PFGROUPSDSETOUT     Name of participant flow reporting groups    (Blank)
|                     dataset used to create the XML file.
|                     Valid values: Blank or A valid SAS dataset
|                     name
|
| PFMSTONEDSETOUT     Name of participant flow milestone dataset   (Blank)
|                     used to create the XML file.
|                     Valid values: Blank or A valid SAS dataset
|                     name
|
| PFWITHDRAWDSETOUT   Name of participant flow withdrawal dataset  (Blank)
|                     used to create the XML file. 
|                     Valid values: Blank or A valid SAS dataset
|                     name
|
|-------------------------------------------------------------------------------
| Output: XML results files via tu_cr8xml4vctr
|         The macro will optionally produce output datasets for the datasets
|         passed into into tu_cr8xml4vctr
|-------------------------------------------------------------------------------
| Global macro variables created: NONE
|-------------------------------------------------------------------------------
| Macros called:
|(@) tu_putglobals
|(@) tu_abort
|(@) tu_tidyup
|(@) tu_chknames
|(@) tu_chkvarsexist
|(@) tu_words
|(@) tu_quotelst
|(@) tu_nobs
|(@) tu_chkdups
|(@) tu_cr8xml4vctr
|-------------------------------------------------------------------------------
| Examples:
|    %tu_mapdddata4vctr
|-------------------------------------------------------------------------------
| Change Log
|
| Modified By: 
| Date of Modification: 
| New version number: 
| Modification ID: 
| Reason For Modification: 
|                          
|-----------------------------------------------------------------------------*/

%macro tu_mapdddata4vctr(
  vctrcr8usxmlyn = Y, /* Create US format results XML file for loading into VCTR Y/N */
  vctrcr8euxmlyn = Y, /* Create EU format results XML file for loading into VCTR Y/N */
  vctrstudyid = %upcase(&g_study_id), /* VCTR study identifier */
  vctrtrtdescrfmt = , /* User defined format to format the treatment code to the long treatment text field */
  basecharyn = Y, /* Create Baseline Characteristics XML files for loading into VCTR Y/N */
bcmeasure1 = %nrstr(dsetin=dddata.dm1(where=(tt_segorder=1)), measureTitle='Age continuous', measureUnits='Years', statslist=MEAN STD, tt_decodevarname=tt_decode1, acrossColVarPrefix=tt_result, totalIDvalue=9999),
/* Parameters required to define baseline measure contained within %nrstr() */
bcmeasure2 = %nrstr(dsetin=dddata.dm1(where=(tt_segorder=2 and tt_decode1 ne 'n')), measureTitle = 'Gender, male/female', measureUnits='Participants', tt_codevarname=tt_code1, tt_decodevarname=tt_decode1, acrossColVarPrefix=tt_result, totalIDvalue=9999),
/* As BCMEASURE1 */
bcmeasure3 = %nrstr(dsetin=dddata.dm1(where=(tt_segorder=4 and tt_decode1 ne 'n')), measureTitle="Race/Ethnicity, Customized", measureUnits='Participants', tt_codevarname=tt_code1, tt_decodevarname=tt_decode1, acrossColVarPrefix=tt_result,
totalIDvalue=9999), /* As BCMEASURE1 */
  bcmeasure4 = , /* As BCMEASURE1 */
  bcmeasure5 = , /* As BCMEASURE1 */
  bcmeasure6 = , /* As BCMEASURE1 */
  bcmeasure7 = , /* As BCMEASURE1 */
  bcmeasure8 = , /* As BCMEASURE1 */
  bcmeasure9 = , /* As BCMEASURE1 */
  bcmeasure10 = , /* As BCMEASURE1 */
  bcmeasure11 = , /* As BCMEASURE1 */
  bcmeasure12 = , /* As BCMEASURE1 */
  bcmeasure13 = , /* As BCMEASURE1 */
  bcmeasure14 = , /* As BCMEASURE1 */
  bcmeasure15 = , /* As BCMEASURE1 */
  bcmeasure16 = , /* As BCMEASURE1 */
  bcmeasure17 = , /* As BCMEASURE1 */
  bcmeasure18 = , /* As BCMEASURE1 */
  bcmeasure19 = , /* As BCMEASURE1 */
  bcmeasure20 = , /* As BCMEASURE1 */
  bcmeasuredescrfmt = , /* User defined format to format the baseline measure number to the long baseline measure description field */
  bcgroupsdsetout = , /* Output dataset to contain the baseline characteristics reporting groups data prior to call to the xml creation utility */
  bcdescrdsetout = , /* Output dataset to contain the measure descriptions source data prior to call to the xml creation utility */
  bcresultsdsetout = , /* Output dataset to contain the measure results source data prior to call to the xml creation utility */
  partflowyn = Y, /* Create Participant Flow XML files for loading into VCTR Y/N */
  pfmstone = %nrstr(dsetin=dddata.es1a(where=(tt_segorder=1)), tt_decodevarname=tt_decode1, acrossColVarPrefix=tt_ac), /* Parameters required to define participant flow milestones contained within %nrstr() */
  pfwithdraw = %nrstr(dsetin=dddata.es1a(where=(tt_segorder=2 and left(tt_decode1) eq tt_decode1)), tt_decodevarname=tt_decode1, acrossColVarPrefix=tt_ac), /* Parameters required to define participant flow withdrawal reasons contained within %nrstr() */
  pfaeoutcome = %nrstr(dsetin=dddata.es1a(where=(tt_segorder=4)), tt_decodevarname=tt_decode1, acrossColVarPrefix=tt_ac), /* Parameters required to define participant flow AE leading to withdrawal outcomes contained within %nrstr() */
  pfperiodtitlevars = , /* Code/decode pair of variables used to populate periodID/periodTitle text fields */
  pfwdreasfmt = $wdrawmap., /* User defined format to map withdrawal reasons */
  pftrttypefmt = , /* User defined format to format the treatment code to the treatment type field */
  pfgroupsdsetout = , /* Output dataset to contain the participant flow reporting groups data prior to call to the xml creation utility */
  pfmstonedsetout = , /* Output dataset to contain the participant flow milestone data prior to call to the xml creation utility */
  pfwithdrawdsetout = /* Output dataset to contain the participant flow withdrawal reasons data prior to call to the xml creation utility */
  );

  /*
  / Echo parameter values and global macro variables to the log.
  /----------------------------------------------------------------------------*/

  %local MacroVersion MacroName;
  %let MacroVersion = 1 build 1;
  %let MacroName=&sysmacroname.;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_study_id) 

  %local
    l_i                /* Counter variable used in macro do loops */
    l_wordlist         /* List of words used in macro do loops */
    l_thisword         /* Current word used in macro do loops */
    l_numBCmeasureID   /* Number of BCMEASURE parameters populated */
    l_maxBCmeasureID   /* Number of the highest populated BCMEASURE parameter */
    l_notexist         /* List of variables which do not exist */
    ;

  /*
  / Parameter validation
  /----------------------------------------------------------------------------*/

  %let vctrcr8usxmlyn = %nrbquote(%upcase(&vctrcr8usxmlyn));
  %let vctrcr8euxmlyn = %nrbquote(%upcase(&vctrcr8euxmlyn));
  %let basecharyn = %nrbquote(%upcase(&basecharyn));
  %let partflowyn = %nrbquote(%upcase(&partflowyn));

  %let l_wordlist=VCTRCR8USXMLYN VCTRCR8EUXMLYN BASECHARYN PARTFLOWYN;

  %do l_i = 1 %to %tu_words(&l_wordlist);
    %let l_thisword = %scan(&l_wordlist, &l_i);
    %if ( %qupcase(&&&l_thisword) ne Y ) and ( %qupcase(&&&l_thisword) ne N ) %then 
    %do;
      %put %str(RTE)RROR: &sysmacroname: Value of parameter &l_thisword (=&&&l_thisword) is invalid. Valid value should be Y or N;
      %let g_abort=1;
    %end;
  %end;

  %if %length(&vctrstudyid) eq 0 %then
  %do;
     %put %str(RTE)RROR: &sysmacroname: The parameter VCTRSTUDYID is required.;
     %let g_abort=1;
  %end;

  %if %length(&vctrtrtdescrfmt) gt 0 %then
  %do;

    data _null_;
      rx = prxparse('/^(?:(?:\$(_|[a-z])\w{0,30})|(?:(_|[a-z])\w{0,31}))\./i');
      if not prxmatch(rx, "&vctrtrtdescrfmt") then
      do;
        put "RTE" "RROR: &sysmacroname: Parameter VCTRTRTDESCRFMT (=&vctrtrtdescrfmt) should be either blank or resolve to a valid SAS format name.";
        call symputx('g_abort', '1');
      end;
      call prxfree(rx);
      stop;
    run;

  %end;

  %if &basecharyn=Y %then
  %do;

    %let l_numBCmeasureID=0;
    %let l_maxBCmeasureID=0;

    %do l_i= 1 %to 20;
      %if %length(&&bcmeasure&l_i) gt 0 %then
      %do;
        %let l_numBCmeasureID = %eval(&l_numBCmeasureID + 1);
        %let l_maxBCmeasureID = &l_i;
      %end;
    %end;

    %if &l_numBCmeasureID eq 0 %then
    %do;
      %put %str(RTE)RROR: &sysmacroname: Parameter BASECHARYN has been set to Y but none of BCMEASURE1-BCMEASURE20 have been specified.;
      %let g_abort=1;
    %end;
    %else %if %length(&bcmeasure1) eq 0 %then
    %do;
      %put %str(RTE)RROR: &sysmacroname: Parameter BASECHARYN has been set to Y but BCMEASURE1 is not populated.;
      %let g_abort=1;
    %end;
    %else %if &l_numBCmeasureID ne &l_maxBCmeasureID %then
    %do;
      %put %str(RTE)RROR: &sysmacroname: Parameters BCMEASURE1-BCMEASURE20 must be specified consecutively. For example:;
      %put %str(RTE)RROR: &sysmacroname: - specifying BCMEASURE1, BCMEASURE2 and BCMEASURE3 is allowed.;
      %put %str(RTE)RROR: &sysmacroname: - specifying BCMEASURE1, BCMEASURE3 and BCMEASURE5 is allowed.;
      %let g_abort=1;
    %end;
      
    %if %length(&bcmeasuredescrfmt) gt 0 %then
    %do;

      data _null_;
        rx = prxparse('/^(?:(?:\$(_|[a-z])\w{0,30})|(?:(_|[a-z])\w{0,31}))\./i');
        if not prxmatch(rx, "&bcmeasuredescrfmt") then
        do;
          put "RTE" "RROR: &sysmacroname: Parameter BCMEASUREDESCRFMT (=&bcmeasuredescrfmt) should be either blank or resolve to a valid SAS format name.";
          call symputx('g_abort', '1');
        end;
        call prxfree(rx);
        stop;
      run;

    %end;
      
    %if %length(&bcgroupsdsetout) gt 0 %then
    %do;
      %if %length(%tu_chknames(&bcgroupsdsetout, DATA)) gt 0 %then
      %do;
        %put %str(RTE)RROR: &sysmacroname: Parameter BCGROUPSDSETOUT (=&bcgroupsdsetout) should be either blank or resolve to a valid SAS dataset name.;
        %let g_abort = 1;
      %end;
    %end;

    %if %length(&bcdescrdsetout) gt 0 %then
    %do;
      %if %length(%tu_chknames(&bcdescrdsetout, DATA)) gt 0 %then
      %do;
        %put %str(RTE)RROR: &sysmacroname: Parameter BCDESCRDSETOUT (=&bcdescrdsetout) should be either blank or resolve to a valid SAS dataset name.;
        %let g_abort = 1;
      %end;
    %end;

    %if %length(&bcresultsdsetout) gt 0 %then
    %do;
      %if %length(%tu_chknames(&bcresultsdsetout, DATA)) gt 0 %then
      %do;
        %put %str(RTE)RROR: &sysmacroname: Parameter BCRESULTSDSETOUT (=&bcresultsdsetout) should be either blank or resolve to a valid SAS dataset name.;
        %let g_abort = 1;
      %end;
    %end;

  %end; /* %if &basecharyn=Y %then %do */

  %if &partflowyn=Y %then
  %do;

    %if %length(&pfmstone) eq 0 %then
    %do;
      %put %str(RTE)RROR: &sysmacroname: Parameter PARTFLOWYN has been set to Y but PFMSTONE is not populated.;
      %let g_abort=1;
    %end;

    %if %length(&pfwithdraw) eq 0 %then
    %do;
      %put %str(RTE)RROR: &sysmacroname: Parameter PARTFLOWYN has been set to Y but PFWITHDRAW is not populated.;
      %let g_abort=1;
    %end;

    %if %length(&pfperiodtitlevars) gt 0 and %tu_words(&pfperiodtitlevars) ne 2 %then %do;
      %put %str(RTE)RROR: &sysmacroname: Parameter PFPERIODTITLEVARS (=&pfperiodtitlevars) must contain exactly two variables when specified.;
      %let g_abort=1;
    %end;

    %if %length(&pfwdreasfmt) eq 0 %then
    %do;
      %put %str(RTE)RROR: &sysmacroname: Parameter PARTFLOWYN has been set to Y but PFWDREASFMT is not populated.;
      %let g_abort=1;
    %end;
    %else
    %do;

      data _null_;
        rx = prxparse('/^(?:(?:\$(_|[a-z])\w{0,30})|(?:(_|[a-z])\w{0,31}))\./i');
        if not prxmatch(rx, "&pfwdreasfmt") then
        do;
          put "RTE" "RROR: &sysmacroname: Parameter PFWDREASFMT (=&pfwdreasfmt) should resolve to a valid SAS format name.";
          call symputx('g_abort', '1');
        end;
        call prxfree(rx);
        stop;
      run;

    %end;

    %if %length(&pftrttypefmt) gt 0 %then
    %do;

      data _null_;
        rx = prxparse('/^(?:(?:\$(_|[a-z])\w{0,30})|(?:(_|[a-z])\w{0,31}))\./i');
        if not prxmatch(rx, "&pftrttypefmt") then
        do;
          put "RTE" "RROR: &sysmacroname: Parameter PFTRTTYPEFMT (=&pftrttypefmt) should be either blank or resolve to a valid SAS format name.";
          call symputx('g_abort', '1');
        end;
        call prxfree(rx);
        stop;
      run;

    %end;

    %if %length(&pfgroupsdsetout) gt 0 %then
    %do;
      %if %length(%tu_chknames(&pfgroupsdsetout, DATA)) gt 0 %then
      %do;
        %put %str(RTE)RROR: &sysmacroname: Parameter PFGROUPSDSETOUT (=&pfgroupsdsetout) should be either blank or resolve to a valid SAS dataset name.;
        %let g_abort = 1;
      %end;
    %end;

    %if %length(&pfmstonedsetout) gt 0 %then
    %do;
      %if %length(%tu_chknames(&pfmstonedsetout, DATA)) gt 0 %then
      %do;
        %put %str(RTE)RROR: &sysmacroname: Parameter PFMSTONEDSETOUT (=&pfmstonedsetout) should be either blank or resolve to a valid SAS dataset name.;
        %let g_abort = 1;
      %end;
    %end;

    %if %length(&pfwithdrawdsetout) gt 0 %then
    %do;
      %if %length(%tu_chknames(&pfwithdrawdsetout, DATA)) gt 0 %then
      %do;
        %put %str(RTE)RROR: &sysmacroname: Parameter PFWITHDRAWDSETOUT (=&pfwithdrawdsetout) should be either blank or resolve to a valid SAS dataset name.;
        %let g_abort = 1;
      %end;
    %end;

  %end; /* %if &partflowyn=Y %then %do */

  %if &g_abort eq 1 %then
  %do;
    %tu_abort
  %end;

  /*
  / NORMAL PROCESSING
  /----------------------------------------------------------------------------*/
 
  %local
    prefix             /* Root name for temporary work datasets */
    l_tt_ac_list       /* List of treatment column variable names */
    l_chkdup           /* Macro variable name passed to tu_chkdups */
    ;

  %let prefix = _mapdd4vctr_;  

  /*
  / Delete any existing XML file
  --------------------------------------------------------------------------*/
  
  %if &basecharyn=Y %then
  %do;

    %tu_cr8xml4vctr(
      usage=DELETE,
      datatype=BASECHAR,
      vctrstudyid=&vctrstudyid
      );

  %end; /* %if &basecharyn=Y %then */

  %if &partflowyn=Y %then
  %do;

    %tu_cr8xml4vctr(
      usage=DELETE,
      datatype=PARTFLOW,
      vctrstudyid=&vctrstudyid
      );

  %end; /* %if &partflowyn=Y %then */

  /*
  / Create Baseline Characteristics XML files
  --------------------------------------------------------------------------*/
  
  %if &basecharyn=Y %then
  %do;

    %local
      l_bcparamlist      /* List of expected parameter names within each baseline measure parameter BCMEASUREx */
      l_measurestats     /* List of valid central tendency statistics */
      l_dispersionstats  /* List of valid dispersion statistics */
      ;

    /*
    / Define valid statistics and format for Baseline Measure Description 
    / dataset variables
    ------------------------------------------------------------------------*/

    %let l_measurestats=MEAN MEDIAN GEOMEAN;
    %let l_dispersionstats=STD Q1 Q3 MIN MAX;

    proc format;
      value $bcStatType
        'MEAN'='Mean'
        'STD'= 'Standard Deviation'
        'GEOMEAN' = 'Geometric Mean'
        'MEDIAN' = 'Median'
        'MIN/MAX' = 'Full Range'
        'Q1/Q3' = 'Inter-Quartile Range'
        'NUMBER' = 'Number'
        'NA' = 'Not Applicable'
        ;
    run;

    /*
    / Get parameter names and values for each Baseline Measure
    ------------------------------------------------------------------------*/

    %let l_bcparamlist=dsetin measureTitle otherMeasureTitle measureUnits statslist
      tt_codevarname tt_decodevarname acrossColVarPrefix totalIDvalue;

    %do l_i = 1 %to 20;

      data &prefix.bcmeasure&l_i (keep=measureID paramname paramvalue);
        length measureID 8 paramstring msg_text $32767 parampair paramname paramvalue $200;
        retain measureID &l_i;

        paramstring=resolve(symget("bcmeasure&l_i"));

        /*
        / Define perl regular expression to parse baseline measure text,
        / values expected to be one of:
        / (1) text in single quotes (may not contain a single quote)
        / (2) text in double quotes (may not contain a double quote)
        / (3) any other text up to the next comma
        --------------------------------------------------------------------*/

        regexp = "/\w+\s*=\s*(('[^']*')" || '|("[^"]*")|([^,]*))/';
        re = prxparse(regexp);
        start = 1;
        stop = -1;

        call prxnext(re, start, stop, paramstring, pos, len);

        do while (pos gt 0);
          parampair = substr(paramstring, pos, len);
          j = index(parampair, '=');
          paramname = substr(parampair, 1, j-1);
          paramvalue = dequote(strip(substr(parampair, j+1)));
          call prxnext(re, start, stop, paramstring, pos, len);
          if upcase(paramname) in (%tu_quotelst(%upcase(&l_bcparamlist))) then
            output;
          else do;
            msg_text = "RTW"||"WARNING: &sysmacroname: Unexpected name/value pair ("||strip(parampair)
                    ||") in parameter BCMEASURE&L_I.. Value will be ignored.";
            put msg_text;
          end;
        end;

        call prxfree(re);
      run;

      proc append base=&prefix.bcmeasure_all data=&prefix.bcmeasure&l_i;
      run;

    %end; /* %do l_i = 1 %to 20 */

    /*
    / Transpose baseline measure details into one observation per baseline
    / measure structure eventually needed for XML utility.
    ------------------------------------------------------------------------*/

    proc sort data=&prefix.bcmeasure_all;
      by measureID;
    run;

    proc transpose data = &prefix.bcmeasure_all out = &prefix.bcdescr0 (drop=_name_);
      by measureID;
      id paramname;
      var paramvalue;
    run;

    /*
    / Create template of all expected baseline measure parameters in case
    / any are missing.
    ------------------------------------------------------------------------*/

    data &prefix.bcparam_template;
      length &l_bcparamlist $200;
      array allcharvars {*} _character_;
      do i=1 to dim(allcharvars);
        allcharvars{i}=' ';
      end;
      drop i;
      delete;
    run;

    /*
    / Validate baseline measure details. Since the XML utility macro does
    / more detailed validation some variables only have basic checks.
    / Create the Measure Descriptions dataset at the same time. 
    ------------------------------------------------------------------------*/

    data &prefix.bcdescr (keep=studyID measureID measureTitle otherMeasureTitle measureDescription parameterType
      dispersionType measureUnits rename=(otherMeasureTitle=otherTitle measureUnits=unitOfMeasure));

      if 0 then set &prefix.bcparam_template;
      set &prefix.bcdescr0 end=last;

      length msg_text $32767 parameterType dispersionType $50 meas_stat disp_stat $200 measureDescription $600;
      retain studyID "&vctrstudyid" err_flag 0;

      /*
      / DSETIN must be specified and refer to a dataset that exists
      ------------------------------------------------------------------------*/

      if missing(dsetin) then
      do;
        err_flag=1;
        msg_text="RTE"||"RROR: &sysmacroname: The input dataset DSETIN in parameter BCMEASURE"||strip(put(measureID,8.))
          ||" has not been specified.";
        put msg_text;
      end;
      else if exist(scan(dsetin,1,'(')) eq 0 then
      do;
        err_flag=1;
        msg_text="RTE"||"RROR: &sysmacroname: The input dataset DSETIN(="||strip(dsetin)||") specified in parameter BCMEASURE"
          ||strip(put(measureID,8.))||" does not exist.";
        put msg_text;
      end;
      else
      do;
        call symputx(compress("l_dsetin"||strip(put(measureID,8.))), dsetin);
      end;

      /*
      / MEASURETITLE must be specified (XML utility validates value and that
      / OTHERMEASURETITLE populated when required)
      ------------------------------------------------------------------------*/

      if missing(measureTitle) then
      do;
        err_flag=1;
        msg_text="RTE"||"RROR: &sysmacroname: The value of measureTitle in parameter BCMEASURE"||strip(put(measureID,8.))
          ||" has not been specified.";
        put msg_text;
      end;

      /*
      / MEASUREUNITS must be specified (XML utility validates value)
      ------------------------------------------------------------------------*/

      if missing(measureUnits) then
      do;
        err_flag=1;
        msg_text="RTE"||"RROR: &sysmacroname: The value of measureUnits in parameter BCMEASURE"||strip(put(measureID,8.))
          ||" has not been specified.";
        put msg_text;
      end;

      /*
      / When STATSLIST is missing the assumption is we have a categorical 
      / baseline measure (gender, race etc.) 
      ------------------------------------------------------------------------*/

      if missing(statslist) then
      do;
        meas_stat='NUMBER';
        disp_stat='NA';
      end;

      /*
      / When STATSLIST is specified the assumption is we have a continuous
      / baseline measure (e.g. age in years.)
      ------------------------------------------------------------------------*/

      else
      do;

        meas_stat='';
        disp_stat='';

        /*
        / Parse the measure and dispersion statistics from STATSLIST
        ----------------------------------------------------------------------*/

        do stat_i = 1 to countw(statslist);
          this_stat=upcase(scan(statslist, stat_i));
          if this_stat not in (%tu_quotelst(&l_measurestats) %tu_quotelst(&l_dispersionstats)) then
          do;
            err_flag=1;
            msg_text="RTE"||"RROR: &sysmacroname: The value of statslist in parameter BCMEASURE"||strip(put(measureID,8.))
              ||" contains an invalid value(="||strip(this_stat)||").";
            put msg_text;
          end;
          else if this_stat in (%tu_quotelst(&l_measurestats)) then
            meas_stat=catx('/', meas_stat, this_stat);
          else if this_stat in (%tu_quotelst(&l_dispersionstats)) then
            disp_stat=catx('/', disp_stat, this_stat);
        end;

        %if &g_debug gt 5 %then
        %do;
          put "RTNOTE: &sysmacroname: Measure and dispersion statistics parsed from parameter BCMEASURE" measureID
            statslist= meas_stat= disp_stat=;
        %end;

        /*
        / STATSLIST must contain one central tendency value and either one
        / or two dispersion values *;
        ----------------------------------------------------------------------*/

        if meas_stat not in (%tu_quotelst(&l_measurestats)) then
        do;
          err_flag=1;
          msg_text="RTE"||"RROR: &sysmacroname: The value of statslist=("||strip(statslist)||") in parameter BCMEASURE"
            ||strip(put(measureID,8.))||" must contain exactly one of &l_measurestats.";
          put msg_text;
        end;

        if disp_stat="MAX/MIN" then
          disp_stat="MIN/MAX";
        else if disp_stat="Q3/Q1" then
          disp_stat="Q1/Q3";

        if disp_stat not in ("STD" "MIN/MAX" "Q1/Q3") then
        do;
          err_flag=1;
          msg_text="RTE"||"RROR: &sysmacroname: The value of statslist=("||strip(statslist)||") in parameter BCMEASURE"
            ||strip(put(measureID,8.))||" must contain exactly one or two of &l_dispersionstats.";
          put msg_text;
        end;

      end;

      call symputx(compress("l_measstat"||strip(put(measureID,8.))), meas_stat);
      call symputx(compress("l_dispstat"||strip(put(measureID,8.))), disp_stat);

      parameterType=put(meas_stat, $bcStatType.);
      dispersionType=put(disp_stat, $bcStatType.);;

      /*
      / TT_DECODEVARNAME must be specified (TT_CODEVARNAME is optional)
      ------------------------------------------------------------------------*/

      if missing(tt_decodevarname) then
      do;
        err_flag=1;
        msg_text="RTE"||"RROR: &sysmacroname: The value of tt_decodevarname in parameter BCMEASURE"||strip(put(measureID,8.))
          ||" has not been specified.";
        put msg_text;
      end;
      else
      do;
        call symputx(compress("l_decodevar"||strip(put(measureID,8.))), tt_decodevarname);
      end;

      call symputx(compress("l_codevar"||strip(put(measureID,8.))), tt_codevarname);

      /*
      / ACROSSCOLVARPREFIX must be specified
      ------------------------------------------------------------------------*/

      if missing(acrossColVarPrefix) then
      do;
        err_flag=1;
        msg_text="RTE"||"RROR: &sysmacroname: The value of acrossColVarPrefix in parameter BCMEASURE"||strip(put(measureID,8.))
          ||" has not been specified.";
        put msg_text;
      end;
      else
      do;
        call symputx(compress("l_acrosscolvarprefix"||strip(put(measureID,8.))), acrossColVarPrefix);
      end;

      /*
      / totalIDvalue must be specified
      ------------------------------------------------------------------------*/

      if missing(totalIDvalue) then
      do;
        err_flag=1;
        msg_text="RTE"||"RROR: &sysmacroname: The value of totalIDvalue in parameter BCMEASURE"||strip(put(measureID,8.))
          ||" has not been specified.";
        put msg_text;
      end;
      else
      do;
        call symputx(compress("l_totalID"||strip(put(measureID,8.))), strip(totalIDvalue));
      end;

      /*
      / Populate long baseline measure description
      ------------------------------------------------------------------------*/

      %if %length(&bcmeasuredescrfmt) gt 0 %then
      %do;
        measureDescription=put(measureID,&bcmeasuredescrfmt.);
      %end;
      %else 
      %do;
        measureDescription=' ';
      %end;

      if last then
        call symputx('g_abort', err_flag);

    run;

    %if &g_abort eq 1 %then %do;
      %tu_abort;
    %end;
  
    /*
    / Validate the input dataset for each baseline measure to check there
    / are data and that expected variables exist etc.
    ------------------------------------------------------------------------*/

    %do l_i = 1 %to %tu_nobs(&prefix.bcdescr);

      /*
      / Read the input dataset first so that any dataset options are applied
      ----------------------------------------------------------------------*/

      data &prefix.bcdsetin&l_i;
        set &&l_dsetin&l_i;
      run;

      %if %tu_nobs(&prefix.bcdsetin&l_i) eq 0 %then
      %do;
        %put %str(RTE)RROR: &sysmacroname: The dataset DSETIN(=%trim(&&l_dsetin&l_i)) specified in parameter BCMEASURE&l_i contains 0 observations.;
        %let g_abort=1;
      %end;

      /*
      / Check that code and decode variables exist
      ----------------------------------------------------------------------*/

      %if %length(&&l_codevar&l_i) gt 0 %then
      %do;
        %if %length(%tu_chknames(&&l_codevar&l_i, VARIABLE)) gt 0 %then
        %do;
          %put %str(RTE)RROR: &sysmacroname: The variable TT_CODEVARNAME(=%trim(&&l_codevar&l_i)) specified in parameter BCMEASURE&l_i should resolve to a valid SAS variable name.;
          %let g_abort = 1;
        %end;
        %else %if %length(%tu_chkvarsexist(&prefix.bcdsetin&l_i, &&l_codevar&l_i)) gt 0 %then
        %do;
          %put %str(RTE)RROR: &sysmacroname: The variable TT_CODEVARNAME(=%trim(&&l_codevar&l_i)) specified in parameter BCMEASURE&l_i does not exist in dataset DSETIN(=%trim(&&l_dsetin&l_i)).;
          %let g_abort = 1;
        %end;
      %end;

      %if %length(%tu_chknames(&&l_decodevar&l_i, VARIABLE)) gt 0 %then
      %do;
        %put %str(RTE)RROR: &sysmacroname: The variable TT_DECODEVARNAME(=%trim(&&l_decodevar&l_i)) specified in parameter BCMEASURE&l_i should resolve to a valid SAS variable name.;
        %let g_abort = 1;
      %end;
      %else %if %length(%tu_chkvarsexist(&prefix.bcdsetin&l_i, &&l_decodevar&l_i)) gt 0 %then
      %do;
        %put %str(RTE)RROR: &sysmacroname: The variable TT_DECODEVARNAME(=%trim(&&l_decodevar&l_i)) specified in parameter BCMEASURE&l_i does not exist in dataset DSETIN(=%trim(&&l_dsetin&l_i)).;
        %let g_abort = 1;
      %end;

      /*
      / Check that treatment column variables exist
      ----------------------------------------------------------------------*/

      %let l_tt_ac_list=;

      proc sql noprint;
        select distinct(trim(name)) into : l_tt_ac_list separated by ' '
        from dictionary.columns
        where upcase(libname) eq "WORK" and upcase(memname) = "%upcase(&prefix.bcdsetin&l_i)" and
              upcase(name) like "%upcase(&&l_acrosscolvarprefix&l_i)%";
      quit;

      %if %length(&l_tt_ac_list) eq 0 %then
      %do;
        %put %str(RTE)RROR: &sysmacroname: The across column prefix(=&&l_acrosscolvarprefix&l_i) specified in parameter BCMEASURE&l_i does not resolve to any variables which exist in dataset DSETIN(=%trim(&&l_dsetin&l_i)).;
        %let g_abort = 1;
      %end;

      /*
      / Check that total group exists
      ----------------------------------------------------------------------*/

      %else %if %sysfunc(indexw(&l_tt_ac_list, &&l_acrosscolvarprefix&l_i.&&l_totalID&l_i)) eq 0 %then
      %do;
        %put %str(RTE)RROR: &sysmacroname: Total variable(=&&l_acrosscolvarprefix&l_i.&&l_totalID&l_i) specified in parameter BCMEASURE&l_i does not exist in dataset DSETIN(=%trim(&&l_dsetin&l_i)).;
        %let g_abort = 1;
      %end;

    %end; /* %do l_i = 1 %to %tu_nobs(&prefix.bcdescr) */

    %if &g_abort eq 1 %then %do;
      %tu_abort;
    %end;
  
    /*
    / Process the input dataset for each baseline measure to get the
    / result values
    ------------------------------------------------------------------------*/

    %do l_i = 1 %to %tu_nobs(&prefix.bcdescr);

      /*
      / Standardise summary statistic labels for continuous measures
      /--------------------------------------------------------------------*/

      %if %upcase(&&l_measstat&l_i) ne NUMBER %then
      %do;

        data &prefix.bcdsetin&l_i;
          set &prefix.bcdsetin&l_i;
          &&l_decodevar&l_i=upcase(compress(&&l_decodevar&l_i,'.'));
          if &&l_decodevar&l_i='SD' then &&l_decodevar&l_i='STD';
          if substr(&&l_decodevar&l_i,1,4)='GEOM' then &&l_decodevar&l_i='GEOMEAN';
        run;

      %end; /* %if %upcase(&&l_measstat&l_i) ne NUMBER */

      /*
      / Tranpose final reporting dataset to get across treatment column
      / variables (e.g. tt_ac:) into single column (trtarmcd/trtarm)
      /--------------------------------------------------------------------*/

      proc sort data=&prefix.bcdsetin&l_i;
        by &&l_codevar&l_i &&l_decodevar&l_i;
      run;

      %tu_chkdups(
        dsetin=&prefix.bcdsetin&l_i,
        byvars=&&l_codevar&l_i &&l_decodevar&l_i,
        dsetout=&prefix.chkdups,
        retvar=l_chkdup
        );
        
      %if &l_chkdup gt 0 %then %do;
        %put %str(RTE)RROR: &sysmacroname: Duplicate values for %upcase(&&l_codevar&l_i &&l_decodevar&l_i) exist in dataset DSETIN(=%trim(&&l_dsetin&l_i)).;
        %let g_abort=1;
        %tu_abort;
      %end;

      /*
      / For frequency measures (e.g. gender) keep the category values
      / (e.g. male/female) as a column to become measureCategory
      /------------------------------------------------------------------*/

      %if %upcase(&&l_measstat&l_i) eq NUMBER %then
      %do;

        proc transpose
          data = &prefix.bcdsetin&l_i
          out = &prefix.bcdsetin_tran
          name = trtarmcd
          label = trtarm
          prefix=rescol
          ;
          by &&l_codevar&l_i &&l_decodevar&l_i;
          var &&l_acrosscolvarprefix&l_i: ;
        run;

        data &prefix.bcresult&l_i (keep=trtarm trtarmcd measureCategory categoryID parameterValue dispersionSpread
          dispersionLowerLimit dispersionUpperLimit naComment);
          set &prefix.bcdsetin_tran end=last;
          by &&l_codevar&l_i &&l_decodevar&l_i;
          retain categoryID 0 g_abort 0 rx;
          length measureCategory parameterValue dispersionSpread dispersionLowerLimit dispersionUpperLimit $200;

          if _n_ eq 1 then 
          do;

            /*
            / Define a Perl regular expression to capture the frequency component
            / of any text that stores number and percentage in the format of
            / either '0' or 'nnn (nn%)'.
            /--------------------------------------------------------------------*/

            rx = prxparse('/(\d+)/');

          end;

          if first.&&l_decodevar&l_i then categoryID+1;
          measureCategory=strip(compbl(translate(&&l_decodevar&l_i," ","~")));

          /*
          / Get the number of subjects in the category from the transposed 
          / results variables.
          /--------------------------------------------------------------------*/

          if prxmatch(rx, rescol1) then
          do;
            parameterValue = strip(prxposn(rx, 1, rescol1));
          end; 
          else
          do;
            put / "RTE" "RROR: &sysmacroname: expecting frequency results"
                / "in dataset DSETIN(=%trim(&&l_dsetin&l_i)) to be in the format 0 or nnn (nn%)."
                / rescol1 = 
                / ;
            g_abort = 1;
          end;

          dispersionSpread=' ';
          dispersionLowerLimit=' ';
          dispersionUpperLimit=' ';
          naComment=' ';

          if last then
          do;
            call symputx('g_abort', put(g_abort, 1.));
            call prxfree(rx);
          end;

        run;

      %end; /* %if %upcase(&&l_measstat&l_i) eq NUMBER */

      /*
      / For summary stats measures (e.g. age continuous) the category
      / values (mean, SD etc.) become columns 
      /------------------------------------------------------------------*/

      %else
      %do;

        proc transpose
          data = &prefix.bcdsetin&l_i
          out = &prefix.bcdsetin_tran
          name = trtarmcd
          label = trtarm
          ;
          id &&l_decodevar&l_i;
          var &&l_acrosscolvarprefix&l_i:;
        run;

        data &prefix.bcresult&l_i (keep=trtarm trtarmcd measureCategory categoryID parameterValue dispersionSpread
          dispersionLowerLimit dispersionUpperLimit naComment);
          set &prefix.bcdsetin_tran;
          length measureCategory parameterValue dispersionSpread dispersionLowerLimit dispersionUpperLimit $200;

          categoryID=.;
          measureCategory=' ';

          /*
          / Get the summary statistics from the transposed results variables.
          /--------------------------------------------------------------------*/

          parameterValue=strip(&&l_measstat&l_i);

          %if %tu_words(&&l_dispstat&l_i, delim=/) eq 1 %then
          %do;
            dispersionSpread=strip(&&l_dispstat&l_i);
            dispersionLowerLimit=' ';
            dispersionUpperLimit=' ';
          %end;
          %else
          %do;
            dispersionSpread=' ';
            dispersionLowerLimit=strip(%scan(&&l_dispstat&l_i,1));
            dispersionUpperLimit=strip(%scan(&&l_dispstat&l_i,2));
          %end;

          naComment=' ';

        run;

      %end; /* %if %upcase(&&l_measstat&l_i) ne NUMBER */

      /*
      / Derive arm variables from the transposed treatment columns
      /------------------------------------------------------------------*/

      data &prefix.bcresult&l_i (keep=measureID armID armTitle numSubjects measureCategory categoryID parameterValue
        dispersionSpread dispersionLowerLimit dispersionUpperLimit naComment total_flag);
        set &prefix.bcresult&l_i end=last;
        retain measureID &l_i g_abort 0 rx;
        length armTitle $200 total_flag $1;

        if _n_ eq 1 then 
        do;

          /*
          / Define a Perl regular expression to match text in the data dislay
          / column headers. The regular expression will include capturing
          / parentheses, to capture the respective components of the column
          / header that correspond to the label used to identify arm of the
          / comparison group and the 'big N' value.
          /--------------------------------------------------------------------*/

          rx = prxparse('/^(.+)~\(N=(\d+)\)/i');

        end;

        /*
        /  Get armID from the name of the treatment variables (tt_ac001, 
        /  tt_ac002 etc.) which were transposed into TRTARMCD.
        /--------------------------------------------------------------------*/

        armID = input( substr(trtarmcd, %length(&&l_acrosscolvarprefix&l_i)+1), 8.);

        /*
        /  Flag the total group (used in later processing)
        /--------------------------------------------------------------------*/

        if armID=&&l_totalID&l_i then total_flag='Y';

        /*
        / Get armTitle and numSubjects from the variable TRTARM, which 
        / contains the labels of the treatment variables (tt_ac001,
        /  tt_ac002 etc.) which were transposed into TRTARM.
        /--------------------------------------------------------------------*/

        if prxmatch(rx, trtarm) then
        do;
          armTitle = prxposn(rx, 1, trtarm);
          armTitle = strip(compbl(translate(armTitle," ","~")));
          numSubjects = input(prxposn(rx, 2, trtarm), 8.);
        end;
        else
        do;
          put / "RTE" "RROR: &sysmacroname: expecting treatment column"
              / 'labels to be in the format XXXXXXXX~(N=DDD)'
              / trtarm = 
              / ;
          g_abort = 1;   
        end;

        if last then
        do;
          call symputx('g_abort', put(g_abort, 1.));
          call prxfree(rx);
        end;

      run;

      proc append base=&prefix.bcresult_all data=&prefix.bcresult&l_i;
      run;

    %end; /* %do l_i = 1 %to %tu_nobs(&prefix.bcdescr) */

    %if &g_abort eq 1 %then %do;
      %tu_abort;
    %end;
  
    /*
    / Create Reporting Groups and Measure Results datasets for the XML
    / utility macro.
    ------------------------------------------------------------------------*/

    data
      &prefix.bcresults (keep=studyID measureID arm: measureCategory categoryID parameterValue dispersion: naComment)
      &prefix.bcgroups (keep=studyID arm: numSubjects rename=(numSubjects=subjectsAnalyzed))
      ;
      set &prefix.bcresult_all;
      length armDescription $2000;
      retain studyID "&vctrstudyid";

      /*
      / Populate armDescription if format has been specified
      /------------------------------------------------------------------*/

      %if %length(&vctrTrtDescrFmt) gt 0 %then
      %do;
        armDescription=put(armID,&vctrTrtDescrFmt.);
      %end;
      %else 
      %do;
        armDescription=' ';
      %end;

      /*
      / Populate arm variables consistently for Total arm
      /------------------------------------------------------------------*/

      if total_flag='Y' then
      do;
        armID=999;
        armTitle='Total';
        armDescription=' ';
      end;

      output &prefix.bcresults;
      if measureID=1 then
        output &prefix.bcgroups;

    run;

    %if &g_debug ge 5 %then
    %do;

      title "&sysmacroname.: Baseline Characteristics Reporting Groups dataset for XML utility macro";
      proc print data=&prefix.bcgroups width=min;
      run;

      title "&sysmacroname.: Baseline Characteristics Measure Descriptions dataset for XML utility macro";
      proc print data=&prefix.bcdescr width=min;
      run;

      title "&sysmacroname.: Baseline Characteristics Measure Results dataset for XML utility macro";
      proc print data=&prefix.bcresults width=min;
      run;

    %end;

    /*
    / Create XML output datasets if requested
    /---------------------------------------------------------------------*/

    %if %length(&bcgroupsdsetout) gt 0 %then
    %do;
      data &bcgroupsdsetout (label="Baseline Characteristics Reporting Groups dataset for XML utility macro created by &sysmacroname.");
        set &prefix.bcgroups;
      run;
    %end;

    %if %length(&bcdescrdsetout) gt 0 %then
    %do;
      data &bcdescrdsetout (label="Baseline Characteristics Measure Descriptions dataset for XML utility macro created by &sysmacroname.");
        set &prefix.bcdescr;
      run;
    %end;

    %if %length(&bcresultsdsetout) gt 0 %then
    %do;
      data &bcresultsdsetout (label="Baseline Characteristics Measure Results dataset for XML utility macro created by &sysmacroname.");
        set &prefix.bcresults;
      run;
    %end;

    /*
    / Call utility to validate datasets and create XML files
    /---------------------------------------------------------------------*/

    %if &vctrcr8usxmlyn = Y or &vctrcr8euxmlyn=Y %then
    %do;

      %tu_cr8xml4vctr(
        usage=CREATE,
        datatype=BASECHAR,
        cr8usxmlyn=&vctrcr8usxmlyn,
        cr8euxmlyn=&vctrcr8euxmlyn,
        vctrstudyid=&vctrstudyid,
        bcgroupsdset=&prefix.bcgroups ,
        bcdescrdset=&prefix.bcdescr ,
        bcdatadset=&prefix.bcresults
        );

    %end;

  %end; /* %if &basecharyn=Y %then %do */

  /*
  / Create Participant Flow XML files
  --------------------------------------------------------------------------*/
  
  %if &partflowyn=Y %then
  %do;

    %local
      l_pfparamlist      /* List of expected parameter names within each participant flow parameter PFMSTONE, PFWITHDRAW, PFAEOUTCOME */
      pfPeriodID         /* Period number variable */
      pfPeriodtitle      /* Period text variable */
      ;

    %let l_pfparamlist=dsetin tt_decodevarname acrossColVarPrefix;

    %let l_wordlist=PFMSTONE PFWITHDRAW;
    %if %length(&pfaeoutcome) gt 0 %then
      %let l_wordlist=&l_wordlist PFAEOUTCOME;

    %do l_i = 1 %to %tu_words(&l_wordlist);

      %let l_thisword = %scan(&l_wordlist, &l_i);

      data &prefix.pfparam&l_i (keep=pfparamID pfparam paramname paramvalue);
        length pfparamID 8 paramstring msg_text $32767 parampair paramname paramvalue $200 pfparam $20;
        retain pfparamID &l_i pfparam "&l_thisword";

        paramstring=resolve(symget("&l_thisword"));

        /*
        / Define perl regular expression to parse participant flow parameter
        /  text, values expected to be one of:
        / (1) text in single quotes (may not contain a single quote)
        / (2) text in double quotes (may not contain a double quote)
        / (3) any other text up to the next comma
        --------------------------------------------------------------------*/

        regexp = "/\w+\s*=\s*(('[^']*')" || '|("[^"]*")|([^,]*))/';
        re = prxparse(regexp);
        start = 1;
        stop = -1;

        call prxnext(re, start, stop, paramstring, pos, len);

        do while (pos gt 0);
          parampair = substr(paramstring, pos, len);
          j = index(parampair, '=');
          paramname = substr(parampair, 1, j-1);
          paramvalue = dequote(strip(substr(parampair, j+1)));
          call prxnext(re, start, stop, paramstring, pos, len);
          if upcase(paramname) in (%tu_quotelst(%upcase(&l_pfparamlist))) then
            output;
          else do;
            msg_text = "RTW"||"WARNING: &sysmacroname: Unexpected name/value pair ("||strip(parampair)
                    ||") in parameter &L_THISWORD.. Value will be ignored.";
            put msg_text;
          end;
        end;

        call prxfree(re);
      run;

      proc append base=&prefix.pfparam_all data=&prefix.pfparam&l_i;
      run;

    %end; /* %do l_i = 1 %to %tu_words(&l_wordlist) */

    /*
    / Transpose participant flow parameter details into one observation per 
    / parameter structure.
    ------------------------------------------------------------------------*/

    proc sort data=&prefix.pfparam_all;
      by pfparamID pfparam;
    run;

    proc transpose data = &prefix.pfparam_all out = &prefix.pfparam0 (drop=_name_);
      by pfparamID pfparam;
      id paramname;
      var paramvalue;
    run;

    /*
    / Create template of all expected participant flow parameters in case
    / any are missing.
    ------------------------------------------------------------------------*/

    data &prefix.pfparam_template;
      length &l_pfparamlist $200;
      array allcharvars {*} _character_;
      do i=1 to dim(allcharvars);
        allcharvars{i}=' ';
      end;
      drop i;
      delete;
    run;

    /*
    / Validate participant flow parameter details. 
    ------------------------------------------------------------------------*/

    data _null_;

      if 0 then set &prefix.pfparam_template;
      set &prefix.pfparam0 end=last;

      length msg_text $32767;
      retain err_flag 0;

      /*
      / DSETIN must be specified and refer to a dataset that exists
      ------------------------------------------------------------------------*/

      if missing(dsetin) then
      do;
        err_flag=1;
        msg_text="RTE"||"RROR: &sysmacroname: The input dataset DSETIN in parameter "||strip(pfparam)||" has not been specified.";
        put msg_text;
      end;
      else if exist(scan(dsetin,1,'(')) eq 0 then
      do;
        err_flag=1;
        msg_text="RTE"||"RROR: &sysmacroname: The input dataset DSETIN(="||strip(dsetin)||") specified in parameter "
          ||strip(pfparam)||" does not exist.";
        put msg_text;
      end;
      else
      do;
        call symputx(compress("l_dsetin"||strip(put(pfparamID,8.))), dsetin);
      end;

      /*
      / TT_DECODEVARNAME must be specified
      ------------------------------------------------------------------------*/

      if missing(tt_decodevarname) then
      do;
        err_flag=1;
        msg_text="RTE"||"RROR: &sysmacroname: The value of tt_decodevarname in parameter "||strip(pfparam)
          ||" has not been specified.";
        put msg_text;
      end;
      else
      do;
        call symputx(compress("l_decodevar"||strip(put(pfparamID,8.))), tt_decodevarname);
      end;

      /*
      / ACROSSCOLVARPREFIX must be specified
      ------------------------------------------------------------------------*/

      if missing(acrossColVarPrefix) then
      do;
        err_flag=1;
        msg_text="RTE"||"RROR: &sysmacroname: The value of acrossColVarPrefix in parameter "||strip(pfparam)
          ||" has not been specified.";
        put msg_text;
      end;
      else
      do;
        call symputx(compress("l_acrosscolvarprefix"||strip(put(pfparamID,8.))), acrossColVarPrefix);
      end;

      if last then
        call symputx('g_abort', err_flag);

    run;

    %if &g_abort eq 1 %then %do;
      %tu_abort;
    %end;

    /*
    / Validate the input dataset for each participant flow parameter to
    / check there are data and that expected variables exist etc.
    ------------------------------------------------------------------------*/

    %do l_i = 1 %to %tu_words(&l_wordlist);

      %let l_thisword = %scan(&l_wordlist, &l_i);

      /*
      / Read the input dataset first so that any dataset options are applied
      ----------------------------------------------------------------------*/

      data &prefix.pfdsetin&l_i;
        set &&l_dsetin&l_i;
      run;

      %if &l_thisword eq PFMSTONE and %tu_nobs(&prefix.pfdsetin&l_i) eq 0 %then
      %do;
        %put %str(RTE)RROR: &sysmacroname: The dataset DSETIN(=%trim(&&l_dsetin&l_i)) specified in parameter &l_thisword contains 0 observations.;
        %let g_abort=1;
      %end;

      /*
      / Check that decode variable exists
      ----------------------------------------------------------------------*/

      %if %length(%tu_chknames(&&l_decodevar&l_i, VARIABLE)) gt 0 %then
      %do;
        %put %str(RTE)RROR: &sysmacroname: The variable TT_DECODEVARNAME(=%trim(&&l_decodevar&l_i)) specified in parameter &l_thisword should resolve to a valid SAS variable name.;
        %let g_abort = 1;
      %end;
      %else %if %length(%tu_chkvarsexist(&prefix.pfdsetin&l_i, &&l_decodevar&l_i)) gt 0 %then
      %do;
        %put %str(RTE)RROR: &sysmacroname: The variable TT_DECODEVARNAME(=%trim(&&l_decodevar&l_i)) specified in parameter &l_thisword does not exist in dataset DSETIN(=%trim(&&l_dsetin&l_i)).;
        %let g_abort = 1;
      %end;

      /*
      / Check that treatment column variables exist
      ----------------------------------------------------------------------*/

      %let l_tt_ac_list=;

      proc sql noprint;
        select distinct(trim(name)) into : l_tt_ac_list separated by ' '
        from dictionary.columns
        where upcase(libname) eq "WORK" and upcase(memname) = "%upcase(&prefix.pfdsetin&l_i)" and
              upcase(name) like "%upcase(&&l_acrosscolvarprefix&l_i)%";
      quit;

      %if %length(&l_tt_ac_list) eq 0 %then
      %do;
        %put %str(RTE)RROR: &sysmacroname: The across column prefix(=&&l_acrosscolvarprefix&l_i) specified in parameter &l_thisword does not resolve to any variables which exist in dataset DSETIN(=%trim(&&l_dsetin&l_i)).;
        %let g_abort = 1;
      %end;

      /*
      / Check that period variables exist if specified
      ----------------------------------------------------------------------*/

      %if &pfperiodtitlevars ne %then
        %let l_notexist=%tu_chkvarsexist(&prefix.pfdsetin&l_i, &pfperiodtitlevars);
      
      %if &l_notexist ne %then %do;
        %put %str(RTE)RROR: &sysmacroname: Variable(s)(=&l_notexist) specified in parameter PFPERIODTITLEVARS do not exist in dataset DSETIN(=%trim(&&l_dsetin&l_i)).;
        %let g_abort=1;
      %end;

    %end; /* %do l_i = 1 %to %tu_words(&l_wordlist) */

    %if &g_abort eq 1 %then %do;
      %tu_abort;
    %end;
  
    /*
    / Process the input dataset for each participant flow parameter to get the
    / result values
    ------------------------------------------------------------------------*/

    %if &pfperiodtitlevars ne %str() %then
    %do;
      %let pfPeriodID=%scan(&pfperiodtitlevars,1);
      %let pfPeriodtitle=%scan(&pfperiodtitlevars,2);
    %end;

    %do l_i = 1 %to %tu_words(&l_wordlist);

      %let l_thisword = %scan(&l_wordlist, &l_i);

      /*
      / Tranpose final reporting dataset to get across treatment column
      / variables (e.g. tt_ac:) into single column (trtarmcd/trtarm)
      / Keep the category values (completion status, withdrawal reason)
      / as a column to become milestoneTitle, reasonType
      /--------------------------------------------------------------------*/

      proc sort data=&prefix.pfdsetin&l_i;
        by &pfPeriodID &pfPeriodtitle &&l_decodevar&l_i;
      run;

      %tu_chkdups(
        dsetin=&prefix.pfdsetin&l_i,
        byvars=&pfPeriodID &pfPeriodtitle &&l_decodevar&l_i,
        dsetout=&prefix.chkdups,
        retvar=l_chkdup
        );
        
      %if &l_chkdup gt 0 %then %do;
        %put %str(RTE)RROR: &sysmacroname: Duplicate values for %upcase(&pfPeriodID &pfPeriodtitle &&l_decodevar&l_i) exist in dataset DSETIN(=%trim(&&l_dsetin&l_i)).;
        %let g_abort=1;
        %tu_abort;
      %end;

      /*
      / Check there are observations before transposing the dataset, if
      / there are 0 obs (e.g. if no withdrawals) a dummy dataset is created.
      /--------------------------------------------------------------------*/

      %if %tu_nobs(&prefix.pfdsetin&l_i) gt 0 %then
      %do;

        proc transpose
          data = &prefix.pfdsetin&l_i
          out = &prefix.pfdsetin_tran
          name = trtarmcd
          label = trtarm
          prefix=rescol
          ;
          by &pfPeriodID &pfPeriodtitle &&l_decodevar&l_i;
          var &&l_acrosscolvarprefix&l_i: ;
        run;

        data &prefix.pfresult&l_i (keep=studyID periodID periodTitle armID armTitle armDescription resultCategory resultValue);
          set &prefix.pfdsetin_tran end=last;
          by &pfPeriodID &pfPeriodtitle &&l_decodevar&l_i;
          retain studyID "&vctrstudyid" g_abort 0 rx rx2;
          length periodTitle armTitle resultCategory $200 armDescription $2000;

          if _n_ eq 1 then 
          do;

            /*
            / Define a Perl regular expression to match text in the data dislay
            / column headers. The regular expression will include capturing
            / parentheses, to capture the respective components of the column
            / header that correspond to the label used to identify arm of the
            / comparison group and the 'big N' value.
            /--------------------------------------------------------------------*/

            rx = prxparse('/^(.+)~\(N=(\d+)\)/i');

            /*
            / Define a Perl regular expression to capture the frequency component
            / of any text that stores number and percentage in the format of
            / either '0' or 'nnn (nn%)'.
            /--------------------------------------------------------------------*/

            rx2 = prxparse('/(\d+)/');

          end;

          /*
          /  Create period variables
          /--------------------------------------------------------------------*/

          %if &pfperiodtitlevars ne %str() %then
          %do;
            periodID=&pfPeriodID;
            periodTitle=&pfPeriodTitle;
          %end;
          %else
          %do;
            periodID=1;
            periodTitle="Overall Study";
          %end;
      
          /*
          /  Get armID from the name of the treatment variables (tt_ac001, 
          /  tt_ac002 etc.) which were transposed into TRTARMCD.
          /--------------------------------------------------------------------*/

          armID = input(substr(trtarmcd, %length(&&l_acrosscolvarprefix&l_i)+1), 8.);

          /*
          / Get armTitle and numSubjects from the variable TRTARM, which 
          / contains the labels of the treatment variables (tt_ac001,
          /  tt_ac002 etc.) which were transposed into TRTARM.
          /--------------------------------------------------------------------*/

          if prxmatch(rx, trtarm) then
          do;
            armTitle = prxposn(rx, 1, trtarm);
            armTitle = strip(compbl(translate(armTitle," ","~")));
          end;
          else
          do;
            put / "RTE" "RROR: &sysmacroname: expecting treatment column labels in "
                / "dataset DSETIN(=%trim(&&l_dsetin&l_i)) to be in the format XXXXXXXX~(N=DDD)"
                / trtarm = 
                / ;
            g_abort = 1;   
          end;

          /*
          / Populate armDescription if format has been specified
          /-----------------------------------------------------------------*/

          %if %length(&vctrTrtDescrFmt) gt 0 %then
          %do;
            armDescription=put(armID,&vctrTrtDescrFmt.);
          %end;
          %else 
          %do;
            armDescription=' ';
          %end;

          /*
          / Category variable
          /-----------------------------------------------------------------*/

          resultCategory=strip(compbl(translate(&&l_decodevar&l_i," ","~")));

          /*
          / Get the number of subjects in the category from the transposed 
          / results variables.
          /--------------------------------------------------------------------*/

          if prxmatch(rx2, rescol1) then
          do;
            resultValue = input(prxposn(rx2, 1, rescol1), 8.);
          end; 
          else
          do;
            put / "RTE" "RROR: &sysmacroname: expecting frequency results"
                / "dataset DSETIN(=%trim(&&l_dsetin&l_i)) to be in the format 0 or nnn (nn%)."
                / rescol1 = 
                / ;
            g_abort = 1;
          end;

          if last then
          do;
            call symputx('g_abort', put(g_abort, 1.));
            call prxfree(rx);
            call prxfree(rx2);
          end;

        run;

      %end; /* %if %tu_nobs(&prefix.pfdsetin&l_i) gt 0 %then %do */

      %else
      %do;

        data &prefix.pfresult&l_i (keep=studyID periodID periodTitle armID armTitle armDescription resultCategory resultValue);
          set &prefix.pfdsetin&l_i;
          retain studyID "&vctrstudyid";
          length periodTitle armTitle resultCategory $200 armDescription $2000;
          periodID=.;
          periodTitle="";
          armID=.;
          armTitle="";
          armDescription="";
          resultCategory="";
          resultValue=.;
        run;

      %end;

    %end; /* %do l_i = 1 %to %tu_words(&l_wordlist) */

    %if &g_abort eq 1 %then %do;
      %tu_abort;
    %end;

    /*
    / Create Reporting Groups dataset for the XML utility macro.
    ------------------------------------------------------------------------*/

    proc sort data=&prefix.pfresult1 out=&prefix.pfgroups (keep=studyID arm:) nodupkey;
      by armID;
    run;

    data &prefix.pfgroups;
      set &prefix.pfgroups;
      length armType armTypeOther $50;

      %if %length(&pftrttypefmt) gt 0 %then
      %do;
        armType=put(armID,&pftrttypefmt.);
        if upcase(scan(armType,1)) eq "OTHER:" then do;
          armTypeOther=strip(substr(armType,index(armType,":")+1));
          armType='OTHER';
        end;
      %end;
      %else 
      %do;
        armType=' ';
        armTypeOther=' ';
      %end;

    run;

    /*
    / Create Milestones dataset for the XML utility macro:
    /   1. Derive STARTED milestone from the milestone dataset passed
    /   2. Drop WITHDRAWN milestone
    /   3. Derive milestoneID from resulting dataset (1=STARTED, 2=COMPLETED)
    ------------------------------------------------------------------------*/

    proc sort data=&prefix.pfresult1;
      by studyID periodID periodTitle armID armTitle armDescription;
    run;

    proc summary data=&prefix.pfresult1;
      by studyID periodID periodTitle armID armTitle armDescription;
      var resultValue;
      output out=&prefix.pfstarted (drop=_type_ _freq_) sum=milestoneData;
    run;

    data &prefix.pfmstone1 (keep=studyID periodID periodTitle armID armTitle armDescription milestoneTitle milestoneOrder milestoneData);
      set 
        &prefix.pfstarted (in=a) 
        &prefix.pfresult1 (in=b rename=(resultCategory=milestoneTitle resultValue=milestoneData))
        ;
 
      if a then
      do;
        milestoneOrder=1;
        milestoneTitle="STARTED";
      end;
      else
      do;
        if upcase(milestoneTitle)="COMPLETED" then
        do;
          milestoneOrder=2;
          milestoneTitle="COMPLETED";
        end;
        else
          milestoneOrder=3;
      end;
    run;

    proc sort data=&prefix.pfmstone1;
      by milestoneOrder milestoneTitle;
    run;

    data &prefix.pfmstone2 (keep=studyID periodID periodTitle armID armTitle armDescription milestoneTitle milestoneID milestoneData);
      set &prefix.pfmstone1 (where=(indexw(upcase(milestoneTitle),"WITHDRAWN") eq 0 and indexw(upcase(milestoneTitle),"DISCONTINUED") eq 0));
      by milestoneOrder milestoneTitle;
      retain milestoneID 0;
      if first.milestoneTitle then
        milestoneID+1;
    run;

    proc sort data=&prefix.pfmstone2 out=&prefix.pfmstone;
      by periodID armID milestoneID;
    run;

    /*
    / Create Withdrawal Reasons dataset for the XML utility macro.
    ------------------------------------------------------------------------*/

    proc format;
      value $wdrawmap
        "ADVERSE EVENT"="ADVERSE EVENT"
        "NON-FATAL"="ADVERSE EVENT"
        "DEATH"="DEATH"
        "FATAL"="DEATH"
        "LACK OF EFFICACY"="LACK OF EFFICACY"
        "LOST TO FOLLOW-UP"="LOST TO FOLLOW-UP"
        "INVESTIGATOR DISCRETION"="PHYSICIAN DECISION"
        "PHYSICIAN DECISION"="PHYSICIAN DECISION"
        "PREGNANCY"="PREGNANCY"
        "PROTOCOL VIOLATION"="PROTOCOL VIOLATION"
        "PROTOCOL DEVIATION"="PROTOCOL VIOLATION"
        "WITHDREW CONSENT"="WITHDRAWAL BY SUBJECT"
        "WITHDRAWAL BY SUBJECT"="WITHDRAWAL BY SUBJECT"
        other="OTHER"
        ;
    run;

    data &prefix.pfwithdraw1 (keep=studyID periodID periodTitle armID armTitle armDescription reasonType otherReasonName reasonOrder subjectsAffected);
      set 
        &prefix.pfresult2 (in=wdreas rename=(resultValue=subjectsAffected))
        &prefix.pfmstone (in=ongo where=(upcase(resultCategory)='ONGOING') rename=(milestoneTitle=resultCategory milestoneData=subjectsAffected))
        %if &pfaeoutcome ne %str() %then
          &prefix.pfresult3 (in=wdae rename=(resultValue=subjectsAffected));
        ;
      length reasonType otherReasonName $200;

      /*
      / Map Withdrawal Reasons to standard list for the XML utility macro
      ----------------------------------------------------------------------*/

      reasonType=put(upcase(strip(resultCategory)), &pfwdreasfmt.);
      if reasonType="OTHER" then
        otherReasonName=resultCategory;

      if ongo then
        reasonOrder=3;
      else if reasonType ne "OTHER" then
        reasonOrder=1;
      else
        reasonOrder=2;

      /*
      / When AEs leading to withdrawal have been specified, drop the rows
      / from the withdrawal reasons dataset.
      ----------------------------------------------------------------------*/

      %if &pfaeoutcome ne %str() %then
      %do;
        if wdreas and reasonType in ('ADVERSE EVENT' 'DEATH') then
          delete;
      %end;

    run;

    /*
    / Drop any reasons with 0 subjects in all arms (per period)
    ------------------------------------------------------------------------*/

    proc sql noprint;
      create table &prefix.pfwithdraw2 as
      select a.*
      from
        &prefix.pfwithdraw1 a,
        (select periodID, reasonType, otherReasonName, sum(subjectsAffected) as tot_subj 
         from &prefix.pfwithdraw1 
         group by periodID, reasonType, otherReasonName 
         having tot_subj>0) b
      where
        a.periodID=b.periodID and a.reasonType=b.reasonType and a.otherReasonName=b.otherReasonName
      order by reasonOrder, reasonType, otherReasonName
      ;
    quit;

    /*
    / Derive reasonID variable.
    ------------------------------------------------------------------------*/

    data &prefix.pfwithdraw3 (keep=studyID periodID periodTitle armID armTitle armDescription reasonType otherReasonName reasonID subjectsAffected);
      set &prefix.pfwithdraw2;
      by reasonOrder reasonType otherReasonName;
      retain reasonID 0;
      if first.otherReasonName then
        reasonID+1;
    run;

    proc sort data=&prefix.pfwithdraw3 out=&prefix.pfwithdraw;
      by periodID armID reasonID;
    run;

    %if &g_debug ge 5 %then
    %do;

      title "&sysmacroname.: Participant Flow Reporting Groups dataset for XML utility macro";
      proc print data=&prefix.pfgroups width=min;
      run;

      title "&sysmacroname.: Participant Flow Milestones dataset for XML utility macro";
      proc print data=&prefix.pfmstone width=min;
      run;

      title "&sysmacroname.: Participant Flow Withdrawal Reasons dataset for XML utility macro";
      proc print data=&prefix.pfwithdraw width=min;
      run;

    %end;

    /*
    / Create XML output datasets if requested
    /---------------------------------------------------------------------*/

    %if %length(&pfgroupsdsetout) gt 0 %then
    %do;
      data &pfgroupsdsetout (label="Participant Flow Reporting Groups dataset for XML utility macro created by &sysmacroname.");
        set &prefix.pfgroups;
      run;
    %end;

    %if %length(&pfmstonedsetout) gt 0 %then
    %do;
      data &pfmstonedsetout (label="Participant Flow Milestones dataset for XML utility macro created by &sysmacroname.");
        set &prefix.pfmstone;
      run;
    %end;

    %if %length(&pfwithdrawdsetout) gt 0 %then
    %do;
      data &pfwithdrawdsetout (label="Participant Flow Withdrawal Reasons dataset for XML utility macro created by &sysmacroname.");
        set &prefix.pfwithdraw;
      run;
    %end;

    /*
    / Call utility to validate datasets and create XML files
    /---------------------------------------------------------------------*/

    %if &vctrcr8usxmlyn = Y or &vctrcr8euxmlyn=Y %then
    %do;

      %tu_cr8xml4vctr(
        usage=CREATE,
        datatype=PARTFLOW,
        cr8usxmlyn=&vctrcr8usxmlyn,
        cr8euxmlyn=&vctrcr8euxmlyn,
        vctrstudyid=&vctrstudyid,
        pfgroupsdset=&prefix.pfgroups,
        pfmstonedset=&prefix.pfmstone,
        pfwithdrawdset=&prefix.pfwithdraw
        );

    %end;
  
  %end; /* %if &partflowyn=Y %then %do */

  /*
  / Delete temporary datasets used in this macro.
  /----------------------------------------------------------------------------*/

  %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tu_mapdddata4vctr;
