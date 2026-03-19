/******************************************************************************
 | Macro Name    : tu_labelvars
 |
 | Macro Version : 1.0
 |
 | SAS version   : SAS v8.2
 |
 | Created By    : Neeraj Malhotra
 |
 | Date          : 22-May-03
 |
 | Macro Purpose : Add standard labels to variables in the specified dataset
 |
 | Macro Design  : Procedure
 |
 | Input Parameters :
 |
 | NAME         DESCRIPTION                                            DEFAULT
 |
 | DSETIN       Specifies the name of the input dataset
 |
 | DSETOUT      Specifies the name of the output dataset               &DSETIN
 |
 | STYLE        Specifies the style of labels to be added              STD
 |              Valid values: STD - Standard length labels
 |                            SHORT - Abbreviated labels
 |
 | RLBLTBL      Specifies the name of the table to be read from        LABELS
 |              the reporting effort's labels XML file.
 |              Required if global macro variable g_rlblfile is
 |              not blank.
 |
 | SLBLTBL      Specifies the name of the table to be read from        LABELS
 |              the study's labels XML file.
 |              Required if global macro variable g_rlblfile is
 |              not blank.
 |
 | CLBLTBL      Specifies the name of the table to be read from        LABELS
 |              the compound's labels XML file.
 |              Required if global macro variable g_rlblfile is
 |              not blank.
 |
 | TLBLFILE     Specifies the name of the XML file(in REFDATA)         tr_idsl_labels_&gd_language..xml
 |              that contains the HARP RT IDSL labels table
 |
 | TLBLTBL      Specifies the name of the table to be read from        LABELS
 |              HARP RT's labels XML file
 |
 | LIBPFX       Specifies the prefix to be used for all librefs        _LBL
 |              allocated by the macro.  To be used as the first
 |              four(or less) characters of libnames assigned
 |              within the macro.
 |              Valid values: between one and four characters, each
 |                            to be alphabetic or underscore
 |
 |
 |
 | Output: none
 |
 | Global macro variables created: none
 |
 |
 | Macros called :
 |(@) tr_putlocals
 |(@) tu_putglobals
 |(@) tu_chkNames
 |(@) tu_chkVarsExist
 |(@) tu_tidyup
 |(@) tu_abort
 |
 |
 |
 | **************************************************************************
 | Change Log :
 |
 | Modified By :             Andrew Ratcliffe
 | Date of Modification :    04-aug-2003
 | New Version/draft number: 1.0 / 2
 | Modification ID :         ABR01
 | Reason For Modification : Sort rlabel and slabel by varname.
 |                           Use upcase comprehensivley in where for stype.
 |                           Remove dots from length specifications.
 |                           Adopt standard length for STYPE and SHORTLABEL.
 |                           Set varnames in xml to be upper-case.
 |                           Make messages more descriptive.
 |
 |
 | Modified By :             Neeraj Malhotra
 | Date of Modification :    11-aug-2003
 | New Version/draft number: 1.0 / 3
 | Modification ID :         NM01
 | Reason For Modification : Added Check to spot blank values for DSETIN.
 |                           Made messages more descriptive.
 |
 | Modified By :             Andrew Ratcliffe
 | Date of Modification :    13-aug-2003
 | New Version/draft number: 1.0 / 4
 | Modification ID :         ABR02
 | Reason For Modification : Add validation to ensure that neither VARNAME nor
 |                            STDLABEL are blank.
 |
 ******************************************************************************/



%macro tu_labelvars(dsetin   =         ,  /*Input Dataset*/
                    dsetout  =         ,  /*Output Dataset*/
                    style    = STD     ,  /*Label length (STD or SHORT)*/
                    rlbltbl  = LABELS  ,  /*Reporting effort labels table*/
                    slbltbl  = LABELS  ,  /*Study labels table*/
                    clbltbl  = LABELS  ,  /*Compound labels table*/
                    tlblfile = tr_idsl_labels_&g_language..xml, /*HARP RT IDSL labels XML file*/
                    tlbltbl  = LABELS  ,  /*HARP RT IDSL labels table*/
                    LIBPFX   = _LBL       /*Libref prefix*/
                       );

  %local prefix;



  %local MacroVersion;
  %let MacroVersion = 1.0;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_rlblfile g_slblfile g_clblfile g_refdata g_language g_stype);
  %let prefix = _Labelvars;

   /*
   / PARAMETER VALIDATION
   /
   / CHECK THAT DSETIN MUST EXIST
   /-------------------------------------------*/

  %if %length(&dsetin) gt 0 %then %do;

    %if %sysfunc(exist(&dsetin)) eq 0 %then
    %do;
      %put RTE%str(RROR:) TU_LABELVARS: Dataset: &dsetin does not exist.;
      %tu_abort(option=FORCE);
    %end;

  %end;

  %else
  %do;
    %put RTE%str(RROR:) TU_LABELVARS: Input Parameter: DSETIN is Blank.; /*NM01*/
    %tu_abort(option=FORCE);
  %end;

  /*Check that DSETOUT is a valid dataset name*/

  %if %length(%tu_chknames(&dsetout, data)) gt 0 %then
  %do;
    %put RTE%str(RROR:) TU_LABELVARS: Dataset: &dsetout is not a valid dataset name.;
    %tu_abort(option=FORCE);
  %end;


  /*Check that input parameter STYLE has the values "STD" or "SHORT"*/

  %if %index("STD" "SHORT" , "%upcase(&style)") eq 0 %then
  %do;
    %put RTE%str(RROR:) TU_LABELVARS: Input Parameter: STYLE is not a valid value.;  /*NM01*/
    %tu_abort(option=FORCE);
  %end;


  /*
  /Check that LIBPFX is not blank, is no more than four
  / characters in length, each to be alphabetic or underscore
  /
  /------------------------------------------------------------*/

  %if %length(%upcase(&libpfx)) eq 0 %then
  %do;
      %put RTE%str(RROR:) TU_LABELVARS: Input Parameter: libpfx is missing.;
      %tu_abort(option=FORCE);
  %end;
  %else
  %do;  /* libpfx is not blank */

    %if %length(%sysfunc(compress(%upcase(&libpfx)
                                 ,_ABCDEFGHIJKLMNOPQRSTUVWXYZ
                                 )
                        )
               ) gt 0 %then
    %do;
      %put RTE%str(RROR:) TU_LABELVARS: Input Parameter: LIBPFX does not begin with an underscore or alphabetic character.;
      %tu_abort(option=FORCE);
    %end;


    %if %length(&libpfx) gt 4 %then
    %do;
      %put RTE%str(RROR:) TU_LABELVARS: Input Parameter: LIBPFX is greater than 4 characters in length.;
      %tu_abort(option=FORCE);
    %end;

  %end; /* libpfx is not blank */


 /*****************REPORTING LEVEL FILE VALIDATION*****************/



  /*If parameters G_RLBLFILE and RLBLTBL are not blank then check that the file and table exists*/


  %if %length(&G_RLBLFILE) gt 0 and  %length(&RLBLTBL) gt 0 %then
  %do;
    %if %sysfunc(fileexist(&g_rlblfile)) eq 0 %then
    %do;
      %put RTE%str(RROR:) TU_LABELVARS: XML FILE: &g_rlblfile does not exist;
      %tu_abort(option=FORCE);
    %end;

    /*Convert the XML Table(s) into dataset(s)*/
    libname &libpfx.rlbl xml "&g_rlblfile";

    /*Check that the table has the variables - VARNAME, STDLABEL and SHORTLABEL*/
    %if %length(%tu_chkvarsexist(dsetin=&libpfx.rlbl.&rlbltbl
                                ,varsin=VARNAME STDLABEL SHORTLABEL
                                )
               ) gt 0 %then
    %do;
      %put RTE%str(RROR:) TU_LABELVARS: Dataset: &dsetin or Variables: VARNAME STDLABEL SHORTLABEL do not exist;
      %tu_abort(option=FORCE);
    %end;

    data &prefix.rlabel;
      length varname $40 stdlabel shortlabel $256;     /* ABR01 */
      set &libpfx.rlbl.&rlbltbl;
      varname=upcase(varname);     /* ABR01 */
      
      select;
        when (varname eq '')   /* ABR02 */
        do;
          put "RTE" "RROR: TU_LABELVARS: Reporting-effort label table contains a blank variable name at row " _n_;
          put "RTN" "OTE: TU_LABELVARS: Reporting-effort label table is &g_rlblfile";
          call symput('G_ABORT','1');
        end;
        when (stdlabel eq '')   /* ABR02 */
        do;
          put "RTE" "RROR: TU_LABELVARS: Reporting-effort label table contains a blank STDLABEL for " varname;
          put "RTN" "OTE: TU_LABELVARS: Reporting-effort label table is &g_rlblfile";
          call symput('G_ABORT','1');
        end;
        otherwise;
      end;
    run;

    /* Sort data ready for merge later */        /* ABR01 */
    proc sort data=&prefix.rlabel out=&prefix.rlabel2;
      by varname;
    run;

  %end;

 /*****************STUDY LEVEL FILE VALIDATION*****************/



  /*If parameters G_SLBLFILE and SLBLTBL are not blank then check that the file and table exists*/

  %if %length(&G_SLBLFILE) gt 0 and  %length(&SLBLTBL) gt 0 %then
  %do;
    %if %sysfunc(fileexist(&g_slblfile)) eq 0 %then
    %do;
      %put RTE%str(RROR:) TU_LABELVARS: XML FILE: &g_slblfile does not exist;
      %tu_abort(option=FORCE);
    %end;

    /*Convert the XML Table(s) into dataset(s)*/
    libname &libpfx.slbl xml "&g_slblfile";

    /*Check that the table has the variables - VARNAME, STDLABEL and SHORTLABEL*/
    %if %length(%tu_chkvarsexist(dsetin=&libpfx.slbl.&slbltbl
                                ,varsin=VARNAME STDLABEL SHORTLABEL
                                )
                ) gt 0 %then %do;
      %put RTE%str(RROR:) TU_LABELVARS: Dataset: &dsetin or Variables: VARNAME STDLABEL SHORTLABEL do not exist;
      %tu_abort(option=FORCE);
    %end;

    data &prefix.slabel;
      length varname $40 stdlabel shortlabel $256;       /* ABR01 */
      set &libpfx.slbl.&slbltbl;
      varname=upcase(varname);     /* ABR01 */
      
      select;
        when (varname eq '')   /* ABR02 */
        do;
          put "RTE" "RROR: TU_LABELVARS: Study label table contains a blank variable name at row " _n_;
          put "RTN" "OTE: TU_LABELVARS: Study label table is &g_slblfile";
          call symput('G_ABORT','1');
        end;
        when (stdlabel eq '')   /* ABR02 */
        do;
          put "RTE" "RROR: TU_LABELVARS: Study label table contains a blank STDLABEL for " varname;
          put "RTN" "OTE: TU_LABELVARS: Study label table is &g_slblfile";
          call symput('G_ABORT','1');
        end;
        otherwise;
      end;
    run;

    /* Sort data ready for merge later */        /* ABR01 */
    proc sort data=&prefix.slabel out=&prefix.slabel2;
      by varname;
    run;

  %end;

 /*****************COMPOUND LEVEL FILE VALIDATION*****************/



  /*If parameters G_CLBLFILE and CLBLTBL are not blank then check that the file and table exists*/

  %if %length(&G_CLBLFILE) gt 0 and  %length(&CLBLTBL) gt 0 %then
  %do;
    %if %sysfunc(fileexist(&g_clblfile)) eq 0 %then
    %do;
      %put RTE%str(RROR:) TU_LABELVARS: XML FILE: &g_clblfile does not exist;
      %tu_abort(option=FORCE);
    %end;

    /*Convert the XML Table(s) into dataset(s)*/
    libname &libpfx.clbl xml "&g_clblfile";

    /*Check that the table has the variables - VARNAME, STDLABEL and SHORTLABEL*/
    %if %length(%tu_chkvarsexist(dsetin=&libpfx.clbl.&clbltbl
                                ,varsin=VARNAME STDLABEL SHORTLABEL
                                )
                ) gt 0 %then
    %do;
      %put RTE%str(RROR:) TU_LABELVARS: Dataset: &dsetin or Variables: VARNAME STDLABEL SHORTLABEL do not exist;
      %tu_abort(option=FORCE);
    %end;

    data &prefix.clabel;
      length varname $40 stdlabel shortlabel $256 stype $3;      /* ABR01 */
      set &libpfx.clbl.&clbltbl;
      varname=upcase(varname);     /* ABR01 */
      
      select;
        when (varname eq '')   /* ABR02 */
        do;
          put "RTE" "RROR: TU_LABELVARS: Compound label table contains a blank variable name at row " _n_;
          put "RTN" "OTE: TU_LABELVARS: Compound label table is &g_clblfile";
          call symput('G_ABORT','1');
        end;
        when (stdlabel eq '')   /* ABR02 */
        do;
          put "RTE" "RROR: TU_LABELVARS: Compound label table contains a blank STDLABEL for " varname;
          put "RTN" "OTE: TU_LABELVARS: Compound label table is &g_clblfile";
          call symput('G_ABORT','1');
        end;
        otherwise;
      end;
    run;

    data &prefix.clabel2;
      set &prefix.clabel;
      if stype eq '' then stype='ALL';
    run;

    proc sort data=&prefix.clabel2;
      by varname;
      where upcase(stype) in ("ALL" "%upcase(&g_stype)");    /* ABR01 */
    run;

  %end;

 /*****************IDSL LEVEL FILE VALIDATION*****************/


  %if %sysfunc(fileexist(&g_refdata./&tlblfile)) eq 0 %then
  %do;
    %put RTE%str(RROR:) TU_LABELVARS: XML FILE: &g_refdata./&tlblfile does not exist;    /* ABR01 */
    %tu_abort(option=FORCE);
  %end;

  libname &libpfx.ilbl xml "&g_refdata./&tlblfile";

  /*Check that the table has the variables - VARNAME, STDLABEL and SHORTLABEL*/
  %if %length(%tu_chkvarsexist(dsetin=&libpfx.ilbl.&tlbltbl
                              ,varsin=VARNAME STDLABEL SHORTLABEL
                              )
             ) gt 0 %then
  %do;
    %put RTE%str(RROR:) TU_LABELVARS: Dataset: &dsetin or Variables: VARNAME STDLABEL SHORTLABEL do not exist;
    %tu_abort(option=FORCE);
  %end;

  data &prefix.ilabel;
    length varname $40 stdlabel shortlabel $256 stype $3;      /* ABR01 */
    set &libpfx.ilbl.&tlbltbl;
    varname=upcase(varname);     /* ABR01 */
    
    select;
      when (varname eq '')   /* ABR02 */
      do;
        put "RTE" "RROR: TU_LABELVARS: IDSL label table contains a blank variable name at row " _n_;
        put "RTN" "OTE: TU_LABELVARS: IDSL label table is &g_refdata/&tlblfile";
        call symput('G_ABORT','1');
      end;
      when (stdlabel eq '')   /* ABR02 */
      do;
        put "RTE" "RROR: TU_LABELVARS: IDSL label table contains a blank STDLABEL for " varname;
        put "RTN" "OTE: TU_LABELVARS: IDSL label table is &g_refdata/&tlblfile";
        call symput('G_ABORT','1');
      end;
      otherwise;
    end;
  run;




  /*IDSL Standards*/



  data &prefix.ilabel2;
    set &prefix.ilabel;
    if stype eq '' then stype='ALL';
  run;

  proc sort data=&prefix.ilabel2;
    by varname;
    where upcase(stype) in ("ALL" "%upcase(&g_stype)");    /* ABR01 */
  run;


  /* Trap validation errors before continuing */
  %tu_abort;   /* ABR02 */




  /*Copy dsetin to dsetout*/    /* ABR01 */

  data &dsetout;
    set &dsetin;
  run;

  %if &syserr gt 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname: Failed to copy input to output;
    %tu_abort(option=force);
  %end;

  /*create a masterlabels dataset with variable names and the label to be applied*/

  data &prefix.masterLabels (keep=varname stdlabel);
    merge &prefix.ilabel2
          %if %sysfunc(exist(&prefix.clabel2)) %then &prefix.clabel2;
          %if %sysfunc(exist(&prefix.slabel2)) %then &prefix.slabel2;    /* ABR01 */
          %if %sysfunc(exist(&prefix.rlabel2)) %then &prefix.rlabel2;    /* ABR01 */
          ;
    by varname;
    if "%upcase(&style)" eq "SHORT" then
    do;
      if shortlabel ne '' then
        stdlabel = shortlabel;
    end;
  run;

  /*Getting a list of variables from the input dataset*/

  proc contents data=&dsetin
                out=&prefix.subjectCols (
                                 keep=name
                                 rename=(name=varname)
                                )
                noprint
                ;
  run;

  data &prefix.subjectCols2;
    length varname $40.;
    set &prefix.subjectCols;
  run;


  /*Check to see whether &dsetout has a libname*/

  %if %index(&dsetout,.) gt 0 %then
  %do;
    %let dsetoutlib=%scan(&dsetout,1,.);
    %let dsetoutmem=%scan(&dsetout,2,.);
  %end;

  %else
  %do;
    %let dsetoutlib=WORK;
    %let dsetoutmem=&dsetout;
  %end;


  data &prefix.subjectCols3;
    set &prefix.subjectCols2;
    varname=upcase(varname);
  run;

  proc sort data=&prefix.subjectCols3;
    by varname;
  run;

  /*Assign the labels to the variables from the input dataset*/

  data &prefix.result;
    merge &prefix.masterLabels (in=fromMstr)
          &prefix.subjectCols3 (in=fromSubj)
          end=finish
          ;
    by varname;
    if _n_ eq 1 then
    do;
      call execute("PROC DATASETS LIB=&dsetoutlib NOLIST;");
      call execute("  MODIFY &dsetoutmem;");
    end;
    if fromSubj and fromMstr then
    do;
      call execute('LABEL ' !! trim(varname) !! '=' !! quote(trim(stdlabel)) !! ';');
    end;
    if finish then
    do;
      call execute('QUIT;');
    end;
  run;

  /*DE-ASSIGNING LIBNAMES*/

  /*If libref has been assigned then clear it*/

  %if not %sysfunc(libref(&libpfx.rlbl)) %then
  %do;
    libname &libpfx.rlbl clear;
  %end;

  %if not %sysfunc(libref(&libpfx.slbl)) %then
  %do;
    libname &libpfx.slbl clear;
  %end;

  %if not %sysfunc(libref(&libpfx.clbl)) %then
  %do;
    libname &libpfx.clbl clear;
  %end;

  %if not %sysfunc(libref(&libpfx.ilbl)) %then
  %do;
    libname &libpfx.ilbl clear;
  %end;

  %tu_tidyup(glbmac=none,rmdset=&prefix:);

%mend tu_labelvars;
