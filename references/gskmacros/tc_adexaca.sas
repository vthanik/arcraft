/******************************************************************************* 
| Program Name: tc_adexaca.sas
|
| Program Version: 1 build 1
|
| HARP Compound/Study/Reporting Effort: 
|
| Program Purpose: To create the ADaM analysis dataset of Exacerbations domain using the ADaM ADEXAC dataset
|   
|
| SAS Version: SAS v9.3
|
| Created By: Robert Croft (rlc25434)
| Date:       16/02/2015
|
|******************************************************************************* 
|
| Output: adamdata.adexaca
|
|
|
| Nested Macros: 
| (@) tu_adgetadslvars
| (@) tu_adgettrt
| (@) tu_attrib
| (@) tu_adperiod
| (@) tu_decode
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_misschk
| (@) tu_tidyup
| (@) tu_chknames
| (@) tu_chkvarsexist
| (@) tu_nobs
| (@) tu_abort
|
| Metadata:
|
|
|******************************************************************************* 
| Change Log 
|
| Modified By: 
| Date of Modification: 
|
| Modification ID: 
| Reason For Modification: 
|                          
|
********************************************************************************/ 
%macro tc_adexaca(dsetin=adamdata.adexac (where=(anl02fl eq 'Y')),  /* Input dataset ADAMDATA.ADEXAC */
               dsetout=adamdata.adexaca,   /* Output dataset to be created */
               getadslvarsyn=Y,            /* Flag to indicate if tu_adgetadslvars utility need to be called */
               dsetinadsl=adamdata.adsl,   /* Input ADSL or ADTRT dataset */          
               adslvars=siteid age sex race acountry trtsdt trtedt trtseq: complfl fasfl ittfl saffl pprotfl, /* List of variable from DSETINADSL dataset for tu_adgetadslvars utility to merge on by USUBJID*/
               adperiodyn=N,               /* Flag to indicate if tu_adperiod utility is to be executed Y/N */
               adgettrtyn=Y,               /* Flag to indicate if tu_adgettrt utility is to be executed Y/N */
               adgettrtmergevars=usubjid,  /* Variables used to merge treatment information from DSETINADSL onto work dataset */
               adgettrtvars=trt01pn trt01p trt01an trt01a, /* List of variables from treatment dataset DSETINADSL for tu_adgettrt utility to add to work dataset */
               decodeyn=Y,                 /* Flag to indicate if tu_decode utility is to be executed Y/N */
               decodepairs=aphasen aphase, /* A list of paired code/decode variables for which the decode is to be created*/ 
               codepairs=paramn param,     /* A list of paired code/decode variables for which the code is to be created*/
               misschkyn=Y,                /* Flag to indicate if tu_misschk utility is to be executed Y/N */
               attributesyn=Y,             /* Flag to indicate if tu_attrib utility is to be executed Y/N */
               populationflag=ittfl        /* Population Flag variable used to subset those subjects to include in summaries */
               );


  /*
  / Echo parameter values and global macro variables to the log.
  /----------------------------------------------------------------------------*/

  %local MacroVersion;
  %let MacroVersion = 1 build 1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_dsplanfile g_abort g_refdata);

  /*
  /  Set up local macro variables
  / ---------------------------------------------------------------------------*/

  %local prefix lastdset ontrtfl_missing postrtfl_missing;   
  %let prefix = _adexaca;

  /*
  / PARAMETER VALIDATION
  /----------------------------------------------------------------------------*/

  %let dsetin            = %nrbquote(&dsetin.);
  %let dsetout           = %nrbquote(&dsetout.);
  %let getadslvarsyn     = %nrbquote(%upcase(&getadslvarsyn.));
  %let adperiodyn        = %nrbquote(%upcase(&adperiodyn.));
  %let adgettrtyn        = %nrbquote(%upcase(&adgettrtyn.));
  %let decodeyn          = %nrbquote(%upcase(&decodeyn.));
  %let attributesyn      = %nrbquote(%upcase(&attributesyn.));
  %let misschkyn         = %nrbquote(%upcase(&misschkyn.));
  %let populationflag    = %nrbquote(%upcase(&populationflag.));
  

  /* Validating if non-missing values are provided for parameters DSETIN and DSETOUT */
  %if &dsetin. eq %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETIN is a required parameter, provide a dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &dsetout. eq %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETOUT is a required parameter, provide a dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;


  /* calling tu_chknames to validate name provided in DSETIN parameter */
  %if %tu_chknames(%scan(&dsetin, 1, %str(%() ), DATA ) ne %then %do;
     %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETIN refers to dataset &dsetin which is not a valid dataset name;
     %let g_abort = 1;
     %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;


  /* Validating if DSETIN dataset exists */
  %if %SYSFUNC(EXIST(%scan(&dsetin, 1, %str(%() ) )) NE 1 %then %do;
     %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETIN refers to dataset %upcase("&dsetin.") which does not exist.;
     %let g_abort = 1;
     %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;


  /* Validating if DSETOUT is a valid dataset name and DSETOUT is not same as DSETIN */
  %if %qupcase(&dsetout.) eq %qupcase(%scan(&dsetin, 1, %str(%() )) %then                /*update to only look at dataset component only*/
  %do;
    %put RTE%str(RROR:) &sysmacroname.: The Output dataset name is same as Input dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;
  /* calling tu_chknames to validate name provided in DSETOUT parameter */
  %else %if %tu_chknames(&dsetout., DATA) ne %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETOUT refers to dataset %nrbquote(%upcase("&dsetout.")) which is not a valid dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;

  /* Validating GETADSLVARSYN, ADGETTRTYN, ADPERIODYN, DECODEYN, ATTRIBUTESYN, MISSCHKYN and POPULATIONFLAG parameters */     
  %if &getadslvarsyn. ne Y and &getadslvarsyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter GETADSLVARSYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &adgettrtyn. ne Y and &adgettrtyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ADGETTRTYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &adperiodyn. ne Y and &adperiodyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ADPERIODYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &decodeyn. ne Y and &decodeyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DECODEYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &attributesyn. ne Y and &attributesyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ATTRIBUTESYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &misschkyn. ne Y and &misschkyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter MISSCHKYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Calling tu_chkvarsexist to validate POPULATIONFLAG parameter name and existence */

  %if &populationflag. ne %str() %then
  %do;

    %let varexst  = %tu_chkvarsexist(&dsetinadsl.,&populationflag.);
    %let varexst2 = %tu_chkvarsexist(&dsetin.,&populationflag.);

    %if &varexst eq -1 %then
    %do;
      %put RTE%str(RROR:) &sysmacroname.: Macro Parameter POPULATIONFLAG %upcase("&populationflag.") has invalid variable name.;
      %let g_abort = 1;
      %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
    %end;
    %else %if &varexst ne %str() %then
    %do;
      %put RTE%str(RROR:) &sysmacroname.: Macro Parameter POPULATIONFLAG refers to variable %upcase("&varexst.") which does not exist in dataset %upcase("&dsetinadsl.").;
      %let g_abort = 1;
      %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
    %end;

    %if &varexst2 ne %str() %then
    %do;
      %put RTE%str(RROR:) &sysmacroname.: Macro Parameter POPULATIONFLAG refers to variable %upcase("&varexst2.") which does not exist in dataset %upcase("&dsetin.").;
      %let g_abort = 1;
      %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
    %end;
       
  %end;

  /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;

  /* Create work dataset if DSETIN contains dataset options */
  %if %index(&dsetin,%str(%() ) gt 0 %then 
  %do;
    data  &prefix._dsetin;
    set %unquote(&dsetin.);
    run;
     
    %let lastdset=&prefix._dsetin;
  %end;
  %else 
  %do;
    %let lastdset=&dsetin;
  %end;



  /*
  / Main Processing starts here.
  / ---------------------------------------------------------------------------*/


  /*Domain specific derivations*/

   /* Derivations */

   /* Retrieve exacerbations (already collapsed in ADEXAC if 
      necessary).
      ANL02FL='Y' indicates exacerbation records that were not
      subject to collapsing (due to occurring <x days apart) as 
      well as derived records for which the collapsing has
      already been performed. */

  proc sort data = &lastdset.
            out = &prefix._adexac;
    by usubjid ceterm astdt aendt;
    %if &populationflag. ne %str() %then where &populationflag.='Y';;
  run;

  data &prefix._adexac2;
    set &prefix._adexac;

    has_exac = 1;

    * Set these flags for anyone who did not have an exacerbation of this type ;
    if missing(hspexb) then hspexb = 'N';
    if missing(erexb) then erexb = 'N';

    * Set combined flag for hospitalization and ER visit ;
    if hspexb eq 'Y' or erexb eq 'Y' then hsp_er = 'Y';
    else hsp_er = 'N';
  run;

  /* Check to see if ONTRTFL, POSTRTFL exist and populated in ADEXAC */

  %if %length(%tu_chkvarsexist(&prefix._adexac2,ontrtfl postrtfl)) eq 0 %then
  %do;

  /* Check that ONTRTFL and POSTRTFL values are not all missing */

    %let ontrtfl_missing=0;
    %let postrtfl_missing=0;
      proc sql noprint;
        select count(*) into :ontrtfl_missing
        from &prefix._adexac2
        where missing(ontrtfl);
      quit;

      proc sql noprint;
        select count(*) into :postrtfl_missing
        from &prefix._adexac2
        where missing(postrtfl);
      quit;

  %if &ontrtfl_missing. ne %tu_nobs(&prefix._adexac2) and &postrtfl_missing. ne %tu_nobs(&prefix._adexac2) %then 
  %do;

   /* Derive TYPEFL and ASTDT per phase per subject */

   data &prefix._type;
     set &prefix._adexac;
       if ontrtfl = 'Y' then flag1 = 1;
       if postrtfl = 'Y' then flag2 = 1;
     keep usubjid ceterm astdt flag1 flag2;
   run;

   data &prefix._type_on;
     set &prefix._type;
     where flag1 = 1;
     aphasen=1;
     typefl='Y';
   run;

   data &prefix._type_post;
     set &prefix._type;
     where flag2 = 1;
     aphasen=2;
     typefl='Y';
   run;

   proc sort data=&prefix._type_on out=&prefix._type_on1;
     by usubjid ceterm descending astdt;
   run;

   proc sort data=&prefix._type_post out=&prefix._type_post1;
     by usubjid ceterm descending astdt;
   run;

   proc sort data=&prefix._type_on1 out=&prefix._type_on2 nodupkey;
     by usubjid ceterm;
   run;

   proc sort data=&prefix._type_post1 out=&prefix._type_post2 nodupkey;
     by usubjid ceterm;
   run;

  /* Number of on-treatment exacerbations for each subject, by
     overall -- any exacerbation, exac causing hospitalization,
     exac causing hosp/ER visit, exac resulting in withdrawal, and
     exac requiring corticosteroids.
     FIRSTDT=date of first event in that category */

  proc summary data = &prefix._adexac2 (where = (ontrtfl eq 'Y')) nway missing chartype;
    class usubjid ceterm hspexb hsp_er ctsexb ocsexb intubexb erexb;
    id studyid;
    types usubjid*ceterm
          usubjid*ceterm*hspexb
          usubjid*ceterm*hsp_er  
          usubjid*ceterm*ctsexb
          usubjid*ceterm*ocsexb
          usubjid*ceterm*intubexb
          usubjid*ceterm*erexb; 
    var has_exac astdt;
    output out = &prefix._exacN_ontrt 
           sum(has_exac) = aval
           min(astdt) = firstdt
           / noinherit;
  run;

  /* Number of post-treatment exacerbations by overall -- any exacerbation, 
     exac causing hospitalization, exac causing hosp/ER visit, 
     and  exac requiring corticosteroids */

  proc summary data = &prefix._adexac2 (where = (postrtfl eq 'Y')) nway missing chartype;
    class usubjid ceterm hspexb hsp_er ctsexb ocsexb intubexb erexb;
    id studyid;
    types usubjid*ceterm
          usubjid*ceterm*hspexb
          usubjid*ceterm*hsp_er 
          usubjid*ceterm*ctsexb
          usubjid*ceterm*ocsexb
          usubjid*ceterm*intubexb
          usubjid*ceterm*erexb;
    var has_exac;
    output out = &prefix._exacN_post
           sum(has_exac) = aval
           / noinherit;
  run;

  /* If there are no subjects with post-treatment exacerbations,
     then create a blank template dataset for these */

  %if %tu_nobs(&prefix._exacN_post) eq 0 %then %do;

    proc sql;
      create table &prefix._exacN_post as
        select distinct _type_, ceterm, hspexb, hsp_er 
        from &prefix._exacN_ontrt;
    quit;

  %end;

  /* Summarize the total number of days hospitalized
     for a exacerbation for each subject
     (on-treatment events only) */

  proc summary data = &prefix._adexac2 (where = (ontrtfl eq 'Y' and 
                                       hspexb eq 'Y'))
               nway missing;
    class usubjid ceterm;
    var hspdynum;
    output out = &prefix._hspdynum (drop = _:)
           sum = thspdynum
           / noinherit;
  run;

  /* Combine results and set up visit to differentiate on-trt,
     post-treatment */

  data &prefix._exacN;
    set &prefix._exacN_ontrt (in = in_ontrt)
        &prefix._exacN_post (in = in_post);

    if in_ontrt then aphasen = 1;
    else if in_post then do;
      aphasen = 2;
      if missing(usubjid) then usubjid = 'POSTFILL';
    end;
    else aphasen = 3;
  run;

  /* Create a template dataset that is one record per subject,
     APHASEN, _TYPE_HSPEXB and HSP_ER  -- so that
     subjects with zero exacerbations are represented */
  
  %if &populationflag. ne %str() %then 
  %do;
  proc sql;
    create table &prefix._template as
      select a.studyid, a.usubjid, e.aphasen, e._type_, e.ceterm, e.hspexb, e.hsp_er, e.ctsexb, e.ocsexb, e.intubexb, e.erexb
      from &dsetinadsl. (where = (&populationflag. eq 'Y')) as a,
           (select distinct aphasen, _type_, ceterm, hspexb, hsp_er, ctsexb, ocsexb, intubexb, erexb from &prefix._exacN) as e
      order by usubjid, aphasen, ceterm, _type_, hspexb, hsp_er, ctsexb, ocsexb, intubexb, erexb;
  quit;
  %end;
  %else %do;
  proc sql;
    create table &prefix._template as
      select a.studyid, a.usubjid, e.aphasen, e._type_, e.ceterm, e.hspexb, e.hsp_er, e.ctsexb, e.ocsexb, e.intubexb, e.erexb
      from &dsetinadsl. as a,
           (select distinct aphasen, _type_, ceterm, hspexb, hsp_er, ctsexb, ocsexb, intubexb, erexb from &prefix._exacN) as e
      order by usubjid, aphasen, ceterm, _type_, hspexb, hsp_er, ctsexb, ocsexb, intubexb, erexb;
  quit;
  %end;

  proc sort data = &prefix._template nodupkey; 
    by usubjid aphasen ceterm _type_ hspexb hsp_er ctsexb ocsexb intubexb erexb;
  run;

  proc sort data = &prefix._exacN; 
    by usubjid aphasen ceterm _type_ hspexb hsp_er ctsexb ocsexb intubexb erexb;
  run;

  data &prefix._exacN2;
    merge &prefix._exacN
          &prefix._template;
    by usubjid aphasen ceterm _type_ hspexb hsp_er ctsexb ocsexb intubexb erexb;

    if missing(aval) then aval = 0;

    length paramcd $8 param $200;

    select(_type_);
      /* any exacerbation */
      when ('11000000') do;
        paramcd = 'EXACN';
        param   = 'Number of exacerbations';
      end;

      /* any exac requiring ER visit */
      when ('11000001') do;
        paramcd = 'EREXBN';
        param   = 'Number of exacerbations requiring ER visit';
      end;

      /* any exac requiring intubation */
      when ('11000010') do;
        paramcd = 'INTUBEXN';
        param   = 'Number of exacerbations requiring Intubation';
      end;

      /* any exac causing hosp. */
      when ('11100000') do;
        paramcd = 'HOSPN';
        param   = 'Number of exacerbations requiring hospitalization';
      end;

      /* any exac causing hosp/ER */
      when ('11010000') do;
        paramcd = 'HOSPERN';
        param   = 'Number of exacerbations requiring hospitalization or ED visit';
      end; 

      /* any exac requiring CTS */
      when ('11001000') do;
        paramcd = 'CTSEXBN';
        param   = 'Number of exacerbations requiring systemic or oral corticosteroids';
      end; 

      /* any exac requiring OCS */
      when ('11000100') do;
        paramcd = 'OCSEXBN';
        param   = 'Number of exacerbations requiring oral corticosteroids';
      end; 
    end;

    drop _:;
  run;

  /* A subject may have had both HSPEXB=N and HSPEXB=Y records
     (similary for HSP/ER, and CTSEXB) -- keep only those 
     associated with a positive response in that case */

  proc sort data = &prefix._exacN2;
    by usubjid aphasen ceterm paramcd hspexb hsp_er ctsexb ocsexb intubexb erexb;
  run;

  data &prefix._exacN3;
    set &prefix._exacN2;
    by usubjid aphasen ceterm paramcd hspexb hsp_er ctsexb ocsexb intubexb erexb;

    /* Subject had both positive and negative in this category -- keep only positive */
    if first.paramcd and not(last.paramcd) then do;
      if (paramcd eq 'HOSPN' and hspexb eq 'N') or
         (paramcd eq 'HOSPERN' and hsp_er eq 'N') or
         (paramcd eq 'CTSEXBN' and ctsexb eq 'N')or
         (paramcd eq 'OCSEXBN' and ocsexb eq 'N') or
         (paramcd eq 'INTUBEXN' and intubexb eq 'N') or
         (paramcd eq 'EREXBN' and erexb eq 'N') then delete;
    end;

    /* If subject had only negative response then set AVAL to 0 and FIRSTDT to missing, 
      as AVAL in this case actually counts the number of 'N' responses */
    else if first.paramcd and last.paramcd then do;
      if (paramcd eq 'HOSPN' and hspexb eq 'N') or
         (paramcd eq 'HOSPERN' and hsp_er eq 'N') or
         (paramcd eq 'CTSEXBN' and ctsexb eq 'N')or
         (paramcd eq 'OCSEXBN' and ocsexb eq 'N') or
         (paramcd eq 'INTUBEXN' and intubexb eq 'N') or
         (paramcd eq 'EREXBN' and erexb eq 'N') then do;
        aval = 0;
        firstdt = .;
      end;
    end;

    /* Get rid of any placeholder records that were padded in above to 
      account for the post-treatment category in the template (in the case
      that no subjects had post-treatment events) */
    if usubjid eq 'POSTFILL' then delete;

    drop hsp: ctsexb ocsexb intubexb erexb;
  run;

  /* Add in days hospitalized.  
     First, fill in with rows of AVAL=0 for subjects who had
     no clin sig exacerbations leading to hospitalization */
  
  %if &populationflag. ne %str() %then 
  %do;
  proc sql;
    create table &prefix._hspdynum2 as
      select a.studyid, a.usubjid,  
             'THSPEX' as paramcd,
             'Total number of days hospitalized due to a exacerbation' as param,
             ceterm,
             1 as aphasen,
             case
               when (h.thspdynum > 0) then h.thspdynum
               else 0
               end as aval
      from &prefix._hspdynum as h full join &dsetinadsl. (where = (&populationflag. eq 'Y')) as a
      on h.usubjid eq a.usubjid 
      order by a.usubjid;
  quit;

  proc sort data = &prefix._hspdynum2;
    by usubjid aphasen ceterm;
  run;

  proc sql;
    create table &prefix._hspdynum3 as
      select a.studyid, a.usubjid, a.aphasen, e.ceterm
      from &prefix._hspdynum2 as a,
           (select distinct ceterm from &prefix._exacN) as e
      order by usubjid, aphasen, ceterm;
  quit;

  data &prefix._hspdynum4;
    merge &prefix._hspdynum2
          &prefix._hspdynum3 (in=a);
    by usubjid aphasen ceterm;
    if a;
  run;

  data &prefix._hspdynum5;
    set &prefix._hspdynum4;
    if param = '' then do;
    param = 'Total number of days hospitalized due to a exacerbation';
    paramcd = 'THSPEX';
    aval = 0;
    end;
  run;

  %end;
  %else %do;
  proc sql;
    create table &prefix._hspdynum2 as
      select a.studyid, a.usubjid,  
             'THSPEX' as paramcd,
             'Total number of days hospitalized due to a exacerbation' as param,
             ceterm,
             1 as aphasen,
             case
               when (h.thspdynum > 0) then h.thspdynum
               else 0
               end as aval
      from &prefix._hspdynum as h full join &dsetinadsl. as a
      on h.usubjid eq a.usubjid 
      order by a.usubjid;
  quit;

  proc sort data = &prefix._hspdynum2;
    by usubjid aphasen ceterm;
  run;

  proc sql;
    create table &prefix._hspdynum3 as
      select a.studyid, a.usubjid, a.aphasen, e.ceterm
      from &prefix._hspdynum2 as a,
           (select distinct ceterm from &prefix._exacN) as e
      order by usubjid, aphasen, ceterm;
  quit;

  data &prefix._hspdynum4;
    merge &prefix._hspdynum2
          &prefix._hspdynum3 (in=a);
    by usubjid aphasen ceterm;
    if a;
  run;

  data &prefix._hspdynum5;
    set &prefix._hspdynum4;
    if param = '' then do;
    param = 'Total number of days hospitalized due to a exacerbation';
    paramcd = 'THSPEX';
    aval = 0;
    end;
  run;
  %end;

  data &prefix._exacN4;
    set &prefix._exacN3
        &prefix._hspdynum5;
    by usubjid;

    /* All exacerbations are used for parameter category */

    parcat1 = 'All Exacerbations';

  run;

  proc sort data = &prefix._exacN4 nodupkey;
    by usubjid aphasen ceterm paramcd;
  run;

  /* Merge TYPEFL and ASTDT into main dataset */

  data &prefix._exacN5;
    merge &prefix._exacN4 (in=a)
          &prefix._type_on2 (keep=usubjid aphasen ceterm typefl astdt)
          &prefix._type_post2 (keep=usubjid aphasen ceterm typefl astdt);
    by usubjid aphasen ceterm;
    if a;
  run;

  /* Derive DTYPE for 'ballooned' records where aval/avalc are populated */ 

  data &prefix._exacN6;
    set &prefix._exacN5;
    by usubjid aphasen;
    if aval = 0 and typefl = '' then do;
      dtype = 'IMPPHANT';
    end;
  run;

  %let lastdset=&prefix._exacN6;
  %end;
  %else %if &ontrtfl_missing eq %tu_nobs(&prefix._adexac2) and &postrtfl_missing eq %tu_nobs(&prefix._adexac2) %then 
  %do; 
    %put RTE%str(RROR:) &sysmacroname.: ONTRTFL and POSTRTFL should be populated if they exist in ADAMDATA.ADEXAC;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

   /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;

  %end;

  /* If ONTRTFL and POSTRTFL do not exist in ADEXAC then do not derive APHASE/APHASEN */

  %else %if %length(%tu_chkvarsexist(&prefix._adexac2,ontrtfl postrtfl)) ne 0 %then 
  %do;

  /* Derive CETERM and ASTDT from ADEXAC per subject */

   data &prefix._type;
     set &prefix._adexac;
     typefl='Y';
     keep usubjid ceterm astdt typefl;
   run;

   proc sort data=&prefix._type out=&prefix._type_1;
     by usubjid ceterm descending astdt;
   run;

   proc sort data=&prefix._type_1 out=&prefix._type_2 nodupkey;
     by usubjid ceterm;
   run;

  proc summary data = &prefix._adexac2 nway missing chartype;
    class usubjid ceterm hspexb hsp_er ctsexb ocsexb intubexb erexb;
    id studyid;
    types usubjid*ceterm
          usubjid*ceterm*hspexb
          usubjid*ceterm*hsp_er  
          usubjid*ceterm*ctsexb
          usubjid*ceterm*ocsexb
          usubjid*ceterm*intubexb
          usubjid*ceterm*erexb;
    var has_exac astdt;
    output out = &prefix._exacN 
           sum(has_exac) = aval
           min(astdt) = firstdt
           / noinherit;
  run;

  /* Summarize the total number of days hospitalized
     for a exacerbation for each subject */

  proc summary data = &prefix._adexac2 (where = (hspexb eq 'Y'))
               nway missing;
    class usubjid ceterm;
    var hspdynum;
    output out = &prefix._hspdynum (drop = _:)
           sum = thspdynum
           / noinherit;
  run;

  /* Create a template dataset that is one record per subject,
     APHASEN, _TYPE_HSPEXB and HSP_ER  -- so that
     subjects with zero exacerbations are represented */
  
  %if &populationflag. ne %str() %then 
  %do;
  proc sql;
    create table &prefix._template as
      select a.studyid, a.usubjid, e._type_, e.ceterm, e.hspexb, e.hsp_er, e.ctsexb, e.ocsexb, e.intubexb, e.erexb
      from &dsetinadsl. (where = (&populationflag. eq 'Y')) as a,
           (select distinct _type_, ceterm, hspexb, hsp_er, ctsexb, ocsexb, intubexb, erexb from &prefix._exacN) as e
      order by usubjid, ceterm, _type_, hspexb, hsp_er, ctsexb, ocsexb, intubexb, erexb;
  quit;
  %end;
  %else %do;
  proc sql;
    create table &prefix._template as
      select a.studyid, a.usubjid, e._type_, e.ceterm, e.hspexb, e.hsp_er, e.ctsexb, e.ocsexb, e.intubexb, e.erexb
      from &dsetinadsl. as a,
           (select distinct _type_, ceterm, hspexb, hsp_er, ctsexb, ocsexb, intubexb, erexb from &prefix._exacN) as e
      order by usubjid, ceterm, _type_, hspexb, hsp_er, ctsexb, ocsexb, intubexb, erexb;
  quit;
  %end;

  proc sort data = &prefix._template nodupkey; 
    by usubjid ceterm _type_ hspexb hsp_er ctsexb ocsexb intubexb erexb;
  run;

  proc sort data = &prefix._exacN; 
    by usubjid ceterm _type_ hspexb hsp_er ctsexb ocsexb intubexb erexb;
  run;

  data &prefix._exacN2;
    merge &prefix._exacN
          &prefix._template;
    by usubjid ceterm _type_ hspexb hsp_er ctsexb ocsexb intubexb erexb;

    if missing(aval) then aval = 0;

    length paramcd $8 param $200;

    select(_type_);
      /* any exacerbation */
      when ('11000000') do;
        paramcd = 'EXACN';
        param   = 'Number of exacerbations';
      end;

      /* any exac requiring ER visit */
      when ('11000001') do;
        paramcd = 'EREXBN';
        param   = 'Number of exacerbations requiring ER visit';
      end;

      /* any exac requiring intubation */
      when ('11000010') do;
        paramcd = 'INTUBEXN';
        param   = 'Number of exacerbations requiring Intubation';
      end;

      /* any exac causing hosp. */
      when ('11100000') do;
        paramcd = 'HOSPN';
        param   = 'Number of exacerbations requiring hospitalization';
      end;

      /* any exac causing hosp/ER */
      when ('11010000') do;
        paramcd = 'HOSPERN';
        param   = 'Number of exacerbations requiring hospitalization or ED visit';
      end; 

      /* any exac requiring CTS */
      when ('11001000') do;
        paramcd = 'CTSEXBN';
        param   = 'Number of exacerbations requiring systemic or oral corticosteroids';
      end; 

      /* any exac requiring OCS */
      when ('11000100') do;
        paramcd = 'OCSEXBN';
        param   = 'Number of exacerbations requiring oral corticosteroids';
      end; 
    end;

    drop _:;
  run;

  /* A subject may have had both HSPEXB=N and HSPEXB=Y records
     (similary for HSP/ER, and CTSEXB) -- keep only those 
     associated with a positive response in that case */

  proc sort data = &prefix._exacN2;
    by usubjid ceterm paramcd hspexb hsp_er ctsexb ocsexb intubexb erexb;
  run;

  data &prefix._exacN3;
    set &prefix._exacN2;
    by usubjid ceterm paramcd hspexb hsp_er ctsexb ocsexb intubexb erexb;

    /* Subject had both positive and negative in this category -- keep only positive */
    if first.paramcd and not(last.paramcd) then do;
      if (paramcd eq 'HOSPN' and hspexb eq 'N') or
         (paramcd eq 'HOSPERN' and hsp_er eq 'N') or
         (paramcd eq 'CTSEXBN' and ctsexb eq 'N')or
         (paramcd eq 'OCSEXBN' and ocsexb eq 'N') or
         (paramcd eq 'INTUBEXN' and intubexb eq 'N') or
         (paramcd eq 'EREXBN' and erexb eq 'N') then delete;
    end;

    /* If subject had only negative response then set AVAL to 0 and FIRSTDT to missing, 
      as AVAL in this case actually counts the number of 'N' responses */
    else if first.paramcd and last.paramcd then do;
      if (paramcd eq 'HOSPN' and hspexb eq 'N') or
         (paramcd eq 'HOSPERN' and hsp_er eq 'N') or
         (paramcd eq 'CTSEXBN' and ctsexb eq 'N')or
         (paramcd eq 'OCSEXBN' and ocsexb eq 'N') or
         (paramcd eq 'INTUBEXN' and intubexb eq 'N') or
         (paramcd eq 'EREXBN' and erexb eq 'N') then do;
        aval = 0;
        firstdt = .;
      end;
    end;

    drop hsp: ctsexb ocsexb intubexb erexb;
  run;

  /* Add in days hospitalized.  
     First, fill in with rows of AVAL=0 for subjects who had
     no clin sig exacerbations leading to hospitalization */

  %if &populationflag. ne %str() %then 
  %do;
  proc sql;
    create table &prefix._hspdynum2 as
      select a.studyid, a.usubjid,  
             'THSPEX' as paramcd,
             ceterm,
             'Total number of days hospitalized due to a exacerbation' as param,
             case
               when (h.thspdynum > 0) then h.thspdynum
               else 0
               end as aval
      from &prefix._hspdynum as h full join &dsetinadsl. (where = (&populationflag. eq 'Y')) as a
      on h.usubjid eq a.usubjid 
      order by a.usubjid;
  quit;

  proc sort data = &prefix._hspdynum2;
    by usubjid ceterm;
  run;

  proc sql;
    create table &prefix._hspdynum3 as
      select a.studyid, a.usubjid, e.ceterm
      from &prefix._hspdynum2 as a,
           (select distinct ceterm from &prefix._exacN) as e
      order by usubjid, ceterm;
  quit;

  data &prefix._hspdynum4;
    merge &prefix._hspdynum2
          &prefix._hspdynum3 (in=a);
    by usubjid ceterm;
    if a;
  run;

  data &prefix._hspdynum5;
    set &prefix._hspdynum4;
    if param = '' then do;
    param = 'Total number of days hospitalized due to a exacerbation';
    paramcd = 'THSPEX';
    aval = 0;
    end;
  run;
  %end;
  %else %do;
   proc sql;
    create table &prefix._hspdynum2 as
      select a.studyid, a.usubjid,  
             'THSPEX' as paramcd,
             ceterm,
             'Total number of days hospitalized due to a exacerbation' as param,
             case
               when (h.thspdynum > 0) then h.thspdynum
               else 0
               end as aval
      from &prefix._hspdynum as h full join &dsetinadsl. as a
      on h.usubjid eq a.usubjid 
      order by a.usubjid;
  quit;

  proc sort data = &prefix._hspdynum2;
    by usubjid ceterm;
  run;

  proc sql;
    create table &prefix._hspdynum3 as
      select a.studyid, a.usubjid, e.ceterm
      from &prefix._hspdynum2 as a,
           (select distinct ceterm from &prefix._exacN) as e
      order by usubjid, ceterm;
  quit;

  data &prefix._hspdynum4;
    merge &prefix._hspdynum2
          &prefix._hspdynum3 (in=a);
    by usubjid ceterm;
    if a;
  run;

  data &prefix._hspdynum5;
    set &prefix._hspdynum4;
    if param = '' then do;
    param = 'Total number of days hospitalized due to a exacerbation';
    paramcd = 'THSPEX';
    aval = 0;
    end;
  run;
  %end;

  data &prefix._exacN4;
    set &prefix._exacN3
        &prefix._hspdynum5;
    by usubjid;

    /* All exacerbations are used for parameter category */

    parcat1 = 'All Exacerbations';

  run;

  proc sort data = &prefix._exacN4 nodupkey;
    by usubjid ceterm paramcd;
  run;

  /* Merge TYPEFL and ASTDT into main dataset */

  data &prefix._exacN5;
    merge &prefix._exacN4 (in=a)
          &prefix._type_2;
    by usubjid ceterm;
    if a;
  run;

  /* Derive DTYPE for 'ballooned' records where aval/avalc are populated */

  data &prefix._exacN6;
    set &prefix._exacN5;
    if aval = 0 and typefl eq '' then do;
      dtype = 'IMPPHANT';
    end;
  run;

  %let lastdset=&prefix._exacN6;

  %end;

 /* Calling tu_adgetadslvars to fetch specified variables from the ADSL/ADTRT dataset, if getadslvarsyn parameter is Y */

  %if &getadslvarsyn=Y %then
  %do;
    %tu_adgetadslvars(dsetin = &lastdset.,
                      adsldset = &dsetinadsl.,
                      adslvars = &adslvars.,
                      dsetout = &prefix._adslout
                       );

    %let lastdset=&prefix._adslout;
  %end;

  proc sort data = &lastdset;
    by usubjid;
  run;

  /* Calling tu_adperiod to bring in either APERIOD/APERIODC or TPERIOD/TPERIODC from ADTRT dataset in XO studies */

  %if %upcase(&adperiodyn)=Y %then
  %do;
    %tu_adperiod(dsetin = &lastdset.,
                 dsetout = &prefix._period,
                 dsetinadtrt = &dsetinadsl.,
                 eventtype= SP             
                );

    %let lastdset=&prefix._period;
  %end;

 /* Calling tu_adgettrt to assign treatment variables to records also bring in selected "other" variables from adtrt such as period trt start stop etc*/

  %if %upcase(&adgettrtyn)=Y %then
  %do;
    %tu_adgettrt(dsetin=&lastdset.,
                 dsetinadsl=&dsetinadsl.,
                 mergevars=&adgettrtmergevars.,
                 trtvars=&adgettrtvars.,
                 dsetout=&prefix._trt
                );

    %let lastdset=&prefix._trt;
  %end;
    

  /* End of domain specific code */

  /* Calling tu_decode to derive codes or decodes using formats specified in &g_dsplanfile */

  %if %upcase(&decodeyn.) eq Y %then
  %do;
    %tu_decode(dsetin = &lastdset.,
                dsetout= &prefix._decode,
                codepairs=&codepairs,
                decodepairs=&decodepairs,
                dsplan=&g_dsplanfile
               );
  %let lastdset=&prefix._decode;
  %end;



  /* Calling tu_attrib to apply the attributes to the variables in output dataset, if attributesyn parameter is Y. */

  %if %upcase(&attributesyn.) eq Y %then
  %do;
    %tu_attrib (dsetin = &lastdset.,
                dsetout= &dsetout.,
                dsplan = &g_dsplanfile
               );
  %end;%else 
  %do;
     data &dsetout.;
        set &lastdset.;
     run;
  %end;



  %if %tu_nobs(&dsetout) gt 0 %then %do;

    %if %upcase(&misschkyn) eq Y %then
    %do;
        %tu_misschk(dsetin=&dsetout);
    %end;

  %end;


  /* Calling tu_tidyup to delete the temporary datasets. */

  %tu_tidyup(rmdset=&prefix.:, glbmac=none);

%mend tc_adexaca;
