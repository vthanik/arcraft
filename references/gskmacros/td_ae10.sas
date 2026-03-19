/*---------------------------------------------------------------------------------------+
| Macro Name                   : TD_AE10
|
| Macro Version                : 3 build 2
|
| SAS version                  : SAS v8.2
|
| Created By                   : James McGiffen
|
| Date                         : March-2006
|
| Macro Purpose                : This unit creates the IDSL standard Integrated Safety Outputs AE10
|
| Macro Design                 : PROCEDURE STYLE
|
| Input Parameters             :
|
| NAME                DESCRIPTION                                       REQ/OPT  DEFAULT
| ----------------------------------------------------------------------------------------
| acrossvar           Variable used to make the columns of the report       REQ &g_trtcd 
|                     (Passed to %tu_freq)
| acrossvardecode     Decode variable for acrossvar                         OPT  &g_trtgrp  
|                     (Passed to %tu_freq)
| active_code         Active Treatment Code                                 REQ  [blank]
| boty                The pct of the page height of the bottom of the graph REQ  7
| codedecodevarpairs  Variables and variable decode                         REQ  aeptcd aept
|                     (Passed to %tu_freq)
| completetypesvars   Passed to %tu_freq. Specify a list of                 OPT  &g_trtcd
|                     variables which are in GROUPBYVARSANALY and the                     
|                     COMPLETETYPES given by PSOPTIONS should be                          
|                     applied to. If it equals _ALL_, all variables in                    
|                     GROUPBYVARSANALY will be included
| lhoptionsfile       Name of file to create or hold options for LH plot    OPT 
| lhoptionsfileUsage  To (U)se, (C)reate (O)verwrite or (N)one:             REQ  N
|                     Left hand graph options file
| dsetindenom         Input Denominator dataset                             REQ  ardata.pop
| dsetinnumer         Input Numerator dataset                               REQ  ardata.ae
| font                Name of the font to be used in the graph              REQ  swiss
| groupbyvarsdenom    Variables in DSETINDENOM to group the data by when    REQ  &g_trtcd
|                     counting to obtain the denominator (Passed to %tu_freq)
| groupbyvarsnumer    Variables in DESTINNUMER to group the data by when    REQ  &g_trtcd aeptcd aept 
|                     counting to obtain the numerator (Passed to %tu_freq)
| incidence_level     The AE Level at or above which will be displayed      REQ  5
| placebo_code        Placebo Treatment Code                                REQ  [blank]
| rhoptionsfile      Name of file to create or hold options for RH plot     OPT  
| rhoptionsfileUsage To (U)se, (C)reate (O)verwrite or (N)one:              REQ  N
|                     right hand graph options file 
| SortOptions         Sort Options: M = Magnitude of Relative Risk either   REQ  M
|                                   I = Incidence on treatment arm
|                                   T = Total incidence across both arms
|                                   A = Alphabetically by Preferred Term
| Statcalcfile        Name of file to create or hold the statistic code     OPT  
| StatcalcFileUsage   To (U)se, (C)reate (O)verwrite or (N)one:             REQ  N
|                     Statistic calculation file
| statcalcbasedata    The name of the dataset that contains basic stats     REQ  _ae10_lhgraph_ae3
|                     and format  
| topy                The pct of the page height of the top of the graph    REQ  80
| xvar2_var           Name of the variable holding the RR var               REQ  elogrr
| yvar                The name of the variable on the yvar                  REQ  aept
| xvar2_ll            Name of the variable holding the lower limit variable REQ  elo
| xvar2_ul            Name of the variable holding the upper limit variable REQ  ehi
|----------------------------------------------------------------------------------------------
| Output                         :  Optionally 3 output program files
| Global macro variables created :  None
|
| Macros called : 
|  (@) tr_putlocals
|  (@) tu_cr8proghead
|  (@) tu_header
|  (@) tu_footer
|  (@) tu_freq
|  (@) tu_pagenum
|  (@) tu_putglobals
|  (@) tu_valparms
|  (@) tu_chknames
|  (@) tu_abort
|  (@) tu_nobs
|  (@) tu_tidyup
|
| Example:
|
|------------------------------------------------------------------------------------------
| Change Log :
|
| Modified By : Ian Barretto
| Date of Modification : 09May06
| New Version Number : 1 build 2
| Modification ID : 001
| Reason For Modification : Change TOTALFORVAR to be &acrossvar. in tu_freq so that it can
|                           handle XO studies
|------------------------------------------------------------------------------------------
| Modified By : James McGiffen
| Date of Modification : 22Jun06
| New Version Number : 2 build 1
| Modification ID : 002
| Reason For Modification : Add quoting to param validation check
|------------------------------------------------------------------------------------------
| Modified By : Julie Smith
| Date of Modification : 29Jun06
| New Version Number : 3 build 1
| Modification ID : 003
| Reason For Modification : Add upcase to parameter and text in NP08
|------------------------------------------------------------------------------------------
| Modified By : Julie Smith
| Date of Modification : 30Jun06
| New Version Number : 3 build 2
| Modification ID : 004
| Reason For Modification : Make corrections to checking pv 7,8,9,10 area
+---------------------------------------------------------------------------------------*/

%MACRO td_ae10(acrossvar= &g_trtcd        /*Passed to %tu_freq*/
              ,acrossvardecode=&g_trtgrp  /*Passed to %tu_freq*/
              ,active_code     =          /*Active Treatment Code */
              ,boty = 7                   /*The pct of the page height of the bottom of the graph*/
              ,codedecodevarpairs=aeptcd aept /*Passed to %tu_freq*/
              ,completetypesvars=&g_trtcd /*Passed to %tu_freq*/
              ,lhoptionsfile  =           /*Name of file to create or hold options for LH graph*/
              ,lhoptionsfileUsage =N      /*To (U)se, (C)reate (O)verwrite or (N)one: lhgraph  options file*/
              ,dsetinnumer=ardata.ae      /*Input numerator dataset */
              ,dsetindenom= ardata.pop    /*Input denominator dataset */
              ,font = swiss               /*Name of the font to be used in the graph*/
              ,groupbyvarsnumer=&g_trtcd aeptcd aept /*Passed to %tu_freq*/
              ,groupbyvarsdenom=&g_trtcd  /*Passed to %tu_freq*/
              ,placebo_code    =          /*Placebo Treatment Code */
              ,incidence_level =5         /*AE Level Incidence */
              ,rhoptionsfile   =          /*Name of file to create or hold options for RH graph*/
              ,rhoptionsfileUsage =N      /*To (U)se, (C)reate (O)verwrite or (N)one: right hand graph options file*/
              ,Statcalcfile    =          /*Name of file to create or hold the stat code*/
              ,SortOptions     = M        /*Sort options: either M,I,T or A*/
              ,StatcalcFileUsage =N       /*To (U)se, (C)reate (O)verwrite or (N)one: Statistic calculation file*/
              ,statcalcbasedata = _ae10_lhgraph_ae3 /* The name of the dataset that contains basic stats and format*/
              ,topy = 80                  /* The pct of the page height of the top of the graph*/
              ,xvar2_ll = elo             /*Name of the variable holding the lower limit variable*/
              ,xvar2_var =elogrr          /*Name of the variable holding the RR var*/
              ,xvar2_ul = ehi             /*Name of the variable holding the upper limit variable*/
              ,yvar = aept                /*The name of the variable on the yvar*/
              );

  /*----------------------------------------------------------------------*/
  /*--NP01 - Clean up the macro variables */
  %let SortOptions = %upcase(%nrbquote(&SortOptions.));
  %let lhoptionsfileUsage =%upcase(%nrbquote(&lhoptionsfileUsage.));
  %let rhoptionsfileUsage =%upcase(%nrbquote(&rhoptionsfileUsage.));
  %let StatcalcFileUsage =%upcase(%nrbquote(&StatcalcFileUsage.));

  /*----------------------------------------------------------------------*/
  /*--NP02 - Put normal header and macro display information in the log */
  %LOCAL MacroVersion prefix macroversion pv_abort currentdataset;
  %LET MacroVersion = 3 build 2;
  %let macroname = &sysmacroname.;

  * Echo values of local and global macro variables to the log ;
  %INCLUDE "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_dddatasetname g_textfilesfx g_outfile g_trtcd g_trtgrp)
  /*----------------------------------------------------------------------*/
  /*--NP03 - set prefix for work directories */
  %let prefix = %substr(&macroname.,3)_;

  /*----------------------------------------------------------------------*/
  /*--NP04 -  Delete any currently existing display file*/
  %tu_pagenum(usage=DELETE)

  /*----------------------------------------------------------------------*/
  /*--NP05 If &g_analy_disp equals D, go to 'Display from here'              */
  %if %upcase(&g_analy_disp.) eq D %then %do;
    %goto DisplayFromHere ;
  %end;

  /*----------------------------------------------------------------------*/
  /*--NP06 -  Delete G_DDDATASETNAME dataset.*/
  %if %sysfunc(exist(&g_dddatasetname)) %then %do;
    proc datasets memtype=(data view) nolist nodetails
      %if %index(&g_dddatasetname, %str(.)) %then %do;
        library=%scan(&g_dddatasetname, 1, %str(.));
        delete %scan(&g_dddatasetname, 2, %str(.));
      %end;
      %else %do;
        ;
        delete &g_dddatasetname;
      %end;
    run;
    quit;
  %end;

  /*----------------------------------------------------------------------*/
  /*--NP07 - Parameter Validation */
  %let pv_abort = 0;
  /*--PV01 - Dsetin exists */
  %tu_valparms(macroname = &macroname., chktype=dsetExists, pv_dsetin = dsetindenom dsetinnumer, abortyn = Y);

  /*--PV04 - There are observations with the placebo code and that it is supplied*/
  /*--PV05 - There are observations with the active code and that it is supplied*/
  %tu_valparms(macroname=&macroname., chktype= isnotblank,
               pv_varsin = Active_code placebo_code sortoptions statcalcbasedata, abortyn = Y);

  %local placebo_obs active_obs;
  proc sql noprint;
    select count(*) into: placebo_obs from &dsetinnumer. where &g_trtcd = &placebo_code.;
    select count(*) into: active_obs from &dsetinnumer. where &g_trtcd = &active_code.;
  quit;
  %if %eval(&placebo_obs.=0) %then %do;
    %put RTE%STR(RROR): &macroname (PV04): The dataset DSETINNUMER(&dsetinnumer.) has no observations where G_TRTCD(&g_trtcd.) = PLACEBO_CODE(&placebo_code.);
    %let pv_abort = 1;
  %end;
  %if %eval(&active_obs.=0) %then %do;
    %put RTE%STR(RROR): &macroname (PV05): The dataset DSETINNUMER(&dsetinnumer.) has no observations where G_TRTCD(&g_trtcd.) = ACTIVE_CODE(&active_code.);
    %let pv_abort = 1;
  %end;

  /*--PV06 - Incidence level is a number between 0 and 100*/
  %if %datatyp(&incidence_level) = CHAR %then %do;
    %put RTE%STR(RROR): &macroname (PV06): INCIDENCE_LEVEL(&incidence_level.) is character and should be numeric.;
    %let pv_abort = 1;
  %end;
  %else %do;
    data _null_;
      if (0 gt &incidence_level.) or (&incidence_level. > 100) then do;
        put "RTE%STR(RROR): &macroname (PV06): INCIDENCE_LEVEL(&incidence_level) is not between 0 and 100";
        call symput('pv_abort','1');
      end;
    run;
  %end;

  /*for lhoptionsfile, rhoptionsfile and statoptionsfile*/
    /*--PV07 -  - if not blank , the file exists if usage is not C*/
    /*--PV08 -  - if fileusage is U or C then it is populated*/
    /*--PV09 -  - if fileusage is C then it does not already exist*/
  /*end*/
  /*for lhoptionsfileusage rhoptionsfileusage and statcalcfileusage*/
    /*--PV10 - is one of U C N or O*/
  /*end*/

  %local chkfile1 chkfile2 chkfile3 chkfile_opt1 chkfile_opt2 chkfile_opt3
         chkfile_name1 chkfile_name2 chkfile_name3 chkfile_us_name1 chkfile_us_name2 chkfile_us_name3 validvalues;
  %let chkfile1 = &lhoptionsfile.;
  %let chkfile2 = &rhoptionsfile.;
  %let chkfile3 = &Statcalcfile.;
  %let chkfile_opt1 = &lhoptionsfileUsage.;
  %let chkfile_opt2 = &rhoptionsfileUsage.;
  %let chkfile_opt3 = &StatcalcFileUsage.;
  %let chkfile_name1 = lhoptionsfile;
  %let chkfile_name2 = rhoptionsfile;
  %let chkfile_name3 = Statcalcfile;
  %let chkfile_us_name1 = lhoptionsfileUsage.;
  %let chkfile_us_name2 = rhoptionsfileUsage.;
  %let chkfile_us_name3 = StatcalcFileUsage.;
  %let validvalues = UCNO;
  
  %do I = 1 %to 3;
                      
      /* if it's missing */
    %if &&chkfile_opt&i. =  %then %do;
        %put %str(RTE)RROR: &macroname (PV10): %upcase(&&chkfile_us_name&i.) is blank. Should be (U)se, (C)reate, (O)verwrite or (N)one;
        %let pv_abort = 1;
    %end; 
    /* if the value of the ..USAGE variables is not U, C, O or N */

    %else %if %verify(&&chkfile_opt&i.,&validvalues.) ne 0 %then %do;
          %put %str(RTE)RROR: &macroname (PV10): %upcase(&&chkfile_us_name&i.)= &&chkfile_opt&i... It must be (U)se, (C)reate, (O)verwrite or (N)one.;
        %let pv_abort = 1;
    %end; 

    %else %do;  /* proceed if the value is present and has a value of U, C, O or N */
    
     
     %if &&chkfile_opt&i. = N  %then %do;        
       %put %str(RTN)OTE: &macroname (PV10) %upcase(&&chkfile_us_name&i.)is N. No options file specified. Default graph will be produced.;
     %end;        /* if its N  */

        
    %else %if &&chkfile_opt&i.= U or &&chkfile_opt&i. = O  %then %do;
      %if %sysfunc(fileexist(&&chkfile&i)) = 0 %then %do;
        %put %str(RTE)RROR: &macroname (PV08): If %upcase(&&chkfile_us_name&i.) = U or O then the file %upcase(&&chkfile_name&i.)
 (&&chkfile&i) should exist but it does not;
        %let pv_abort = 1;
      %end;
      %else %if &&chkfile&i. = %then %do;
        %put %str(RTE)RROR: &macroname (PV08): If %upcase(&&chkfile_us_name&i.) = U or O then &&chkfile_name&i (&&chkfile&i) should not
 be blank;
        %let pv_abort = 1;
      %end;
     %end;   /* if &&chkfile_opt&i = U or O */

     %else %if &&chkfile_opt&i. = C %then %do;
       /* 002 - add quoting to if statement to stop errors */
       %if %cmpres("&&chkfile&i..") = "" %then %do;
         %put %str(RTE)RROR: &macroname (PV08):If %upcase(&&chkfile_us_name&i.) = C then &&chkfile_name&i (&&chkfile&i) should not be blank;
         %let pv_abort=1;
       %end;
       %else %if %sysfunc(fileexist(&&chkfile&i..)) = 1 %then %do;
         %put %str(RTE)RROR: &macroname (PV09): If %upcase(&&chkfile_us_name&i.) = C then the file %upcase(&&chkfile_name&i.) (&&chkfile&i) should not already exist but it does;
         /* 004 - add back in setting pv_abort to 1 */ 
         %let pv_abort = 1;          
       %end;
     %end;  /* if &&chkfile_opt&i = C */
     
   %end; /* if the value is present and has a value of U, C, O or N */
 %end; /* do i = 1 to 3 */


  /*----------------------------------------------------------------------*/
  /*--PV02 - check that sortoptions is one of the correct values */
  %tu_valparms(macroname = &macroname., chktype = isOneOf, valuelist = M I T A,
               pv_varsin= sortoptions);

  /*----------------------------------------------------------------------*/
  /*--PV03 - Check that statcalcbasedata is a valid dataset name*/
  %if %tu_chknames(namesin = &statcalcbasedata.,nametype = data) ne %then %do;
    %Put %str(RTE)RROR: &macroname.: (PV03) The dataset STATCALCBASEDATA(&statcalcbasedata.) is an invalid name for a dataset;
    %let pv_abort = 1;
  %end;


/*-- check that the parameter validation has passed   */
  %if %eval(&pv_abort.+ &g_abort.) gt 0 %then %tu_abort(option=force); 

  /*----------------------------------------------------------------------*/
  /*--NP08 - change the pdf device to pdfc*/    /* jas upcase text and parameter check to work in HARP app 003 */
  %local device;
  %if &g_textfilesfx=PDF %then %let device=PDFC;
  %else %let device=%upcase(&g_textfilesfx);

  /*----------------------------------------------------------------------*/
  /*--NP09 - Call %tu_freq to calculate counts*/
  /* Modification 001 - change totalforvar to &acrossvar to allow for xo studies */
  %tu_freq(display=N
          ,dsetout=&prefix.lhgraph_ae1
          ,dsetinnumer=&dsetinnumer.
          ,dsetindenom=&dsetindenom.
          ,groupbyvarsnumer=&groupbyvarsnumer.
          ,groupbyvarsdenom=&groupbyvarsdenom.
          ,addbignyn=Y
          ,completetypesvars=&acrossvar.
          ,codedecodevarpairs=&codedecodevarpairs.
          ,denormyn=Y
          ,acrossvar=&acrossvar.
          ,acrossvardecode=&acrossvardecode.
          ,varstodenorm=tt_pct tt_denomcnt
          ,totalforvar=&acrossvar.
          ,totaldecode=Total
          ,totalid=999
  );
  %let currentdataset = &prefix.lhgraph_ae1;

  /*----------------------------------------------------------------------*/
  /*--NP10 -Calculate the basic relative risks */
  
  data _null_;
    call symput("active_code_fmt",put(&active_code.,z3.));
    call symput("placebo_code_fmt",put(&placebo_code.,z3.));
  run;
  
  /*----------------------------------------------------------------------*/
  /*--NP11 - Remove any Adverse events below the incidence rate */
  data &prefix.lhgraph_ae2 (keep=aept tt_ac&placebo_code_fmt. tt_ac&active_code_fmt.
                         tt_denomcnt&placebo_code_fmt. tt_denomcnt&active_code_fmt.
                         &xvar2_var. &xvar2_ll. &xvar2_ul.  tt_ac999);
    set &currentdataset. (where=(tt_ac&placebo_code_fmt. ne 0 or tt_ac&active_code_fmt. ne 0));

    %if &incidence_level ne 0 %then %do;
      temp_placebo_pct=round(tt_ac&placebo_code_fmt.,1.0);
      temp_active_pct=round(tt_ac&active_code_fmt.,1.0);
    %end;
    %else %do;
      temp_placebo_pct=tt_ac&placebo_code_fmt.;
      temp_active_pct=tt_ac&active_code_fmt.;
    %end;

    /*----------------------------------------------------------------------*/
    /*--NP12 - Calculate Relative risk with 95% confidence limits  */
    /* Calculates log RR and 95% CI */
    if tt_ac&placebo_code_fmt. gt 0 and tt_ac&active_code_fmt. gt 0 then do;
       logrr=log(tt_ac&active_code_fmt./tt_ac&placebo_code_fmt.);
       se=sqrt((100/tt_ac&placebo_code_fmt. - 1)/tt_denomcnt&placebo_code_fmt. + (100/tt_ac&active_code_fmt. -1)/tt_denomcnt&active_code_fmt.);
       lower=logrr + se*(-1.96);
       upper=logrr + se*(1.96);
       &xvar2_var.=exp(logrr);
       &xvar2_ll.=exp(lower);
       &xvar2_ul.=exp(upper);
    end;
    /*----------------------------------------------------------------------*/
    /*--NP13 -only keep the records with incidence level at or above the specified level*/
    if temp_placebo_pct ge &incidence_level or temp_active_pct ge &incidence_level then output;
  run;
  %let currentdataset = &prefix.lhgraph_ae2;
  /*-- need to get the maximum frequency of adverse event for the limit of the xaxis*/
  data _null_;
    retain maxFcnt;
    set &currentdataset. end=last;
    maxFcnt = max(tt_ac&placebo_code_fmt., tt_ac&active_code_fmt., sum(maxfcnt,0));
    if last then call symput('maxFcnt', put(ceil(maxFcnt),8.));
  run;

  /*----------------------------------------------------------------------*/
  /*--NP14 - Sort the data dependant on sortoptions */
  %local bystatement;
  %if &sortoptions. =M %then %do;
    %put %str(RTN)OTE: &macroname(NP14): Sorting data by Magnitude of Relative Risk;
    %let bystatement = descending &xvar2_var.;
  %end;
  %else %if &sortoptions. = I %then %do;
    %put %str(RTN)OTE: &macroname(NP14): Sorting data by Incidence on treatment arm;
    %let bystatement = descending tt_ac&active_code_fmt.;
  %end;
  %else %if &sortoptions. = T %then %do;
    %put %str(RTN)OTE: &macroname(NP14): Sorting data by Total Incidence across all arms;
    %let bystatement = descending tt_ac999;
  %end;
  %else %if &sortoptions. = A %then %do;
    %put %str(RTN)OTE: &macroname(NP14): Sorting data Alphabetically by PT;
    %let bystatement = AEPT;
  %end;
  proc sort data=&currentdataset. out=&statcalcbasedata.;
    by &bystatement.;
  run;
  %let currentdataset = &statcalcbasedata.;

  /*----------------------------------------------------------------------*/
  /*--NP15 - Deal with the options of statcalcfileusage*/
  %if &StatcalcFileUsage. = U %then %do;
    %put %str(RTN)OTE: &macroname(NP15): The file STATCALCFILE (&statcalcfile.) has been specified to provide the code for the data for the RH graph ;
    %include "&statcalcfile.";
    %if &syserr. gt 4 %then %do;
      %put %str(RTE)RROR: &macroname(NP15): The code supplied by STATCALCFILE (&statcalcfile.) has caused a SAS error, please review;
      %tu_abort(option = force);
    %end;
  %end;
  %else %if &StatcalcFileUsage = C or &StatcalcFileUsage = O %then %do;
    /*----------------------------------------------------------------------*/
    /*--NP15 - Get the name of the file to pass to the header of the program*/
    %put %str(RTN)OTE: &macroname(NP15): The macro will attempt to create a template for your code in &statcalcfile.;
    filename statcalc "&statcalcfile.";
    data _null_;
      file statcalc;
      %tu_cr8proghead(macname = %sysfunc(reverse(%scan(%sysfunc(reverse(&statcalcfile.)),1,'/\'))));
      put "/*-- the dataset name you can pick up to add to what has been created is &statcalcbasedata.*/;";
      put "data addstat;";
      put "  set &statcalcbasedata.;";
      put "run;";
      put " ";
      put "/*---------------------------------------------------------------------------*/";
      put "/*-- Insert your code to produce the dataset here */";
      put " ";
      put "/*---------------------------------------------------------------------------*/";
      put "/*-- update this let statement to the dataset name that you want graphed     */";
      put %nrstr("%let") " currentdataset = &statcalcbasedata.;";
      put "/*Note: This dataset should contain the following variables */;";
      put "/*&yvar - The variable holding the Y Var (character)*/;";
      put "/*tt_ac&placebo_code_fmt. - The variable holding the count of events for placebo (numeric)*/;";
      put "/*tt_ac&active_code_fmt. - The variable holding the count of events for active (numeric)*/;";
      put "/*tt_denomcnt&placebo_code_fmt. - The variable holding the number of subjects in placebo group (numeric)*/;";
      put "/*tt_denomcnt&active_code_fmt. - The variable holding the count of subjects in active group (numeric)*/;";
      put "/*&xvar2_var. - The variable holding the value of the X variable in right hand graph (numeric)*/;";
      put "/*&xvar2_ll. - The variable holding the lower limit of the X variable in right hand graph (numeric)*/;";
      put "/*&xvar2_ul. - The variable holding the upper limit of the X variable in right hand graph (numeric)*/;";
      put "/*Note: This dataset should be sorted in the order you want displayed*/;";
      put "/*Note: This code should be validated using your own departmental procedures*/;";
    run;
  %end;
  %else %if &StatcalcFileUsage= N %then %do;
    %put%str(RTN)OTE: &macroname(NP15): No StatCalcFile has been specified - continuing to produce standard graph;
  %end;
  
  /*----------------------------------------------------------------------*/
  /*--NP16 - Perform further parameter validation in the current dataset*/
  /*--PV16.1 - Check that data dataset exists */
  %let pv_abort = 0;
  %tu_valparms(macroname = &macroname., chktype=dsetExists, pv_dsetin =statcalcbasedata , abortyn = Y);
  
  /*--PV16.2 - Check that the variables required for the graph exist*/
  %local act_cnt_var pla_cnt_var;
  %let act_cnt_var = tt_ac&placebo_code_fmt.;
  %let pla_cnt_var = tt_ac&active_code_fmt.;
  %tu_valparms(macroname=&macroname., chktype=varExists, pv_dsetin=statcalcbasedata,
               pv_varsin = yvar act_cnt_var pla_cnt_var xvar2_var xvar2_ll xvar2_ul);

  /*----------------------------------------------------------------------*/
  /*--NP17- Create ddataset- */
  %local outdset_obs;
  %let outdset_obs = %tu_nobs(&statcalcbasedata.);
  data &g_dddatasetname;
    set &statcalcbasedata.;
    sort_key=(&outdset_obs.-_n_)+1;
  run;

  %DisplayFromHere:
  /*----------------------------------------------------------------------*/
  /*--NP18 - Create a format for each value of the xvar- */
  data &prefix.yvar_fmt (keep=start label fmtname);
    retain;
    set &g_dddatasetname (rename=(&yvar.=label)) end=eof;
    fmtname='ylabel';
    start = (&outdset_obs.-_n_)+1;
    if eof then do;
      call symput('ptrt_no',tt_denomcnt&placebo_code_fmt.);
      call symput('atrt_no',tt_denomcnt&active_code_fmt.);
    end;
  run;

  proc format cntlin=&prefix.yvar_fmt;
  run;

  /*----------------------------------------------------------------------*/
  /*--NP19 - Create annotate dataset */
  data &prefix.anno;
    set &g_dddatasetname;
    length function $8. ;
    xsys='2'; ysys='2';
    line=1;
    size=1.5;
    /*if there is no relative risk then draw move to center*/
    if &xvar2_ll. ne . then x=&xvar2_ll.; else x = 1;
    y=sort_key;
    function='move'; output;
    /*-- if there is no relative risk then draw nothing*/
    if &xvar2_ul. ne . then x=&xvar2_ul. ; else x=1;
    y=sort_key;
    function='draw'; output;
  run;
  /*----------------------------------------------------------------------*/
  /*--NP20 - get the count of the number of yvar */
  %local aecnt;
  %let aecnt=%tu_nobs(&g_dddatasetname);
  /*----------------------------------------------------------------------*/
  /*--NP21 - Get the treatment labels*/
  proc contents noprint data=&g_dddatasetname
   out=&prefix.trt_labels (where=(name in ("tt_denomcnt&placebo_code_fmt." "tt_denomcnt&active_code_fmt."))
                           keep=name label);
  run;

  data _null_;
    set &prefix.trt_labels;
    if name="tt_denomcnt&placebo_code_fmt." then call symput('ptrt',trim(label) ||' (n= %trim(&ptrt_no))');
    else if name="tt_denomcnt&active_code_fmt." then call symput('atrt',trim(label) ||' (n= %trim(&atrt_no))');
  run;

  /*Creates the initial lhgraph part of the graphic*/
  filename gfileref "&g_outfile..&g_textfilesfx.";
  /*----------------------------------------------------------------------*/
  /*--NP22 - Deal with the options for lhoptionsusage */
  /*--store the default options in a macro variable*/
  %local graph1gopt graph1sym1 graph1sym2 graph1ax1 graph1ax2 graph1leg;
  %let graph1gopt = GOPTIONS reset=all device=&device gsfname=gfileref rotate=landscape gsfmode=replace ftext=&font.  vorigin=1.2in horigin=1in hsize=9.2in vsize=6.2in vpos=60 hpos=90 ;
  %let graph1sym1 = SYMBOL1 f=special v=J h=4 c=blue;
  %let graph1sym2 = SYMBOL2 f=special v=L h=4 c=red;
  %let graph1ax1 = %str(AXIS1 order=(1 to &aecnt by 1) offset=(0.9) minor=none major=none value=(j=r h=12pt) label=(h=10pt  '  ') );
  %let graph1ax2 = %str(AXIS2 order=(0 to &maxfcnt. by 2) offset=(0.2)  label=(h=14pt 'Percent') value=(h=2 t=2 '' t=4 '' t=6 '' t=8 '' t=10 '' t=12 '' t=14 '' t=16 '' t=18 '' t=20 ''););
  %let graph1leg = %str("legend1 value =(font = &font. height = 1.5 '&ptrt' font = &font. height = 1.5 '&atrt.' ) label = none offset = (3cm,) shape = symbol(3,3);");

  /*-- need to create an unquoted legend macro var for code*/
  data _null_;
    call symput('graph1leg_nq', &graph1leg.);
  run;
  /*----------------------------------------------------------------------*/
  /*--NP23 -Set the default graphics options for left hand graph */
  &graph1gopt.;;
  &graph1sym1.;;
  &graph1sym2.;;
  &graph1ax1.;;
  &graph1ax2.;;
  &graph1leg_nq.;;
  /*----------------------------------------------------------------------*/
  /*--NP24 - Deal with the options of lhoptionsfileusage*/
  %if &lhoptionsfileUsage. = U %then %do;
    %put %str(RTN)OTE: &macroname(NP24 ): The file lhoptionsFILE (&lhoptionsfile.) has been specified to provide the options for left hand graph ;
    %include "&lhoptionsfile.";
    %if &syserr. gt 4 %then %do;
      %put %str(RTE)RROR: &macroname(NP24): The code supplied by lhoptionsFILE (&lhoptionsfile.) has caused a SAS error, please review;
      %tu_abort(option = force);
    %end;
  %end;
  %else %if &lhoptionsFileUsage = C or &lhoptionsFileUsage = O %then %do;
    /*----------------------------------------------------------------------*/
    /*--NP24.1 - Get the name of the file to pass to the header of the program*/
    %put %str(RTN)OTE: &macroname(NP24): The macro will attempt to create a template for your code in &lhoptionsfile.;
    filename lhopts "&lhoptionsfile.";
    data _null_;
      file lhopts;
      %tu_cr8proghead(macname = %sysfunc(reverse(%scan(%sysfunc(reverse(&lhoptionsfile.)),1,'/\'))));
      put "&graph1gopt.;";
      put "&graph1sym1.;";
      put "&graph1sym2.;";
      put "&graph1ax1.;";
      put "&graph1ax2.;";
      put &graph1leg.; 
      put "/*Note: This code should be validated using your own departmental procedures*/;";
    run;
  %end;
  %else %if &lhoptionsFileUsage= N %then %do;
    %put %str(RTN)OTE: &macroname(NP24): No options for the left hand graph have been specified - continuing to produce standard graph;
  %end;
  /*----------------------------------------------------------------------*/
  /*--NP24.2 -Draw the left hand graph */
  %if %sysfunc(exist(work.&prefix.graphs,catalog)) %then %do;
    proc catalog c=work.&prefix.graphs kill;
    quit;
  %end;

  proc gplot data=&g_dddatasetname gout = work.&prefix.graphs;
    plot sort_key * tt_ac&placebo_code_fmt. = 1 sort_key * tt_ac&active_code_fmt. = 2 / overlay
     name="lhgraph"
     vaxis=axis1
     haxis=axis2
     lvref=2
     vref= 1 to &aecnt  /*sets number of aes - need changing each time*/
     cvref=gray 
     legend=legend1;
    format sort_key ylabel.;
  run;
  quit;

  /*----------------------------------------------------------------------*/
  /*--NP24.3 -Create header and footer information */
  /*-- created now as it will pick up how many graphs*/
  /*-- This may seem a bit of overkill.. but will allow us to add by variables*/
  /*-- get the number of entries we have in the graphics column*/
  %local numpages; %let numpages = 0;
  data _null_;
    set sashelp.vcatalg (where=(libname eq "WORK" and 
                                memname eq "%upcase(&prefix.graphs)" and
                                memtype eq 'CATALOG' and 
                                objtype eq 'GRSEG' ));
    call symput('NUMPAGES',compress(putn(_n_,'BEST.')));
  run;


  /*----------------------------------------------------------------------*/
  /*--NP25 - Set options for glside*/
  GOPTIONS reset=all device=&device gsfname=gfileref hsize=9.25in vsize=6in horigin=0.88in
           vorigin=1.25in ftext=&font. ftitle=&font. cback=white ctext=black display nocharacters
           gsfmode=replace htext=10pt htitle=10pt xmax=11 in ymax = 8.5 in rotate=landscape
           lfactor=10;
  
  /*----------------------------------------------------------------------*/
  /*--NP26 - call header and footer to capture the footnotes and headers*/
  %tu_header;
  %tu_footer(dsetout=&prefix.footrefdset);

  /*----------------------------------------------------------------------*/
  /*--NP27 -  Create a gslide contaning headers, footers and page x of y s  */
  %annomac;                                
  %do i = 1 %to &numpages;
    data work.&prefix._annohf;
      %dclanno;
      length text $20;
      %system(3,3,4);
      page_text = trim(left(putc('PAGE','$local.')))
                  !! " &i "
                  !! trim(left(putc('OF','$local.')))
                  !! " &numpages"
                  ;
      %label(100,100         /* Position        */
            ,page_text       /* Text            */
            ,black           /* Colour          */
            ,0,0             /* Angle, rotation */
            ,&g_fontsize/7   /* Size            */
            ,&font           /* Font            */
            ,D);             /* Position        */
                   /* 7 is a "fudge-factor" that seems to */
                   /* work when converting sizes.         */
                   /*------------------------------------------------------*/
      OUTPUT;
    run;

    proc gslide gout=work.&prefix.graphs anno=work.&prefix._annohf name="headfoot";
    run; quit;
  %end;

  /*----------------------------------------------------------------------*/
  /*--NP28 - Creates the relative risk and CI part of graphic*/
  %local graph2gopt graph2sym1 graph2sym2 graph2sym3 graph2ax1 graph2ax2;
  %let graph2gopt = GOPTIONS reset=all device=&device gsfname=gfileref rotate=landscape gsfmode=replace ftext=&font. vorigin=1.2in horigin=0.5in hsize=3.2in vsize=6.2in vpos=60 hpos=30 ;
  %let graph2sym1 = SYMBOL1 i=none f=special v=J h=3.2 c=black ;
  %let graph2sym2 = SYMBOL2 i=none f=special v=< h=1 c=black ;
  %let graph2sym3 = SYMBOL3 i=none f=special v=> h=1 c=black ;
  %let graph2ax1 = %str(AXIS1 order=(1 to &aecnt) offset=(0.9) major=none minor=none value=(h=12pt c=white) label=(h=10pt  '  '));
  %let graph2ax2 = %str(AXIS2 order=(0.0 0.125 .25 .5 1 2 4 8 16 32 64) offset=(0.2) minor=none label=(h=12pt 'Relative Risk with 95% CI') value=(h=1.7 t=1 '' t=2 '.125' t=3 '' t=4 '.5' t=5 '1' t=6 '2' t=7 '' t=8 '8' t=9 '' t=10 '32' t=11 '' ););

  /*----------------------------------------------------------------------*/
  /*--NP29 Set the standard goptions for right hand graph*/
  &graph2gopt.;;
  &graph2sym1.;;
  &graph2sym2.;;
  &graph2sym3.;;
  &graph2ax1.;;
  &graph2ax2.;;

  /*----------------------------------------------------------------------*/
  /*--NP30 - Deal with the options of rhoptionsfileusage*/
  %if &rhoptionsfileUsage. = U %then %do;
    %put %str(RTN)OTE: &macroname(NP30): The file rhoptionsFILE (&rhoptionsfile.) has been specified to provide the options for right hand graph ;
    %include "&rhoptionsfile.";
    %if &syserr. gt 4 %then %do;
      %put %str(RTE)RROR: &macroname(NP30): The code supplied by rhoptionsFILE (&rhoptionsfile.) has caused a SAS error, please review;
      %tu_abort(option = force);
    %end;
  %end;
  %else %if &rhoptionsFileUsage = C or &rhoptionsFileUsage = O %then %do;
    /*----------------------------------------------------------------------*/
    /*--NP30.1 - Get the name of the file to pass to the header of the program*/
    %put %str(RTN)OTE: &macroname(NP30.1): The macro will attempt to create a template for your code in &rhoptionsfile.;
    filename rhopts "&rhoptionsfile.";
    data _null_;
      file rhopts;
      %tu_cr8proghead(macname = %sysfunc(reverse(%scan(%sysfunc(reverse(&rhoptionsfile.)),1,'/\'))));
      put "&graph2gopt.;";
      put "&graph2sym1.;";
      put "&graph2sym2.;";
      put "&graph2sym3.;";
      put "&graph2ax1.;";
      put "&graph2ax2.;";
      put "/*Note: This code should be validated using your own departmental procedures*/;";
    run;
  %end;
  %else %if &rhoptionsFileUsage= N %then %do;
    %put %str(RTN)OTE: &macroname(NP30): No Options for the right hand graph have been specified - continuing to produce standard graph;
  %end;

  /*----------------------------------------------------------------------*/
  /*--NP32 -Create the right hand graph */
  proc gplot data=&g_dddatasetname gout = work.&prefix.graphs;
    plot sort_key*&xvar2_var.=1 sort_key*&xvar2_ll.=2 sort_key*&xvar2_ul.=3 / overlay
    name="rhgraph" vaxis=axis1 haxis=axis2 lhref=1 lvref=2 cvref=gray href=1
    vref= 1 to &aecnt  /*sets no. of aes - needs changing each time*/
    annotate=&prefix.anno ;
  run;
  quit;

  /*----------------------------------------------------------------------*/
  /*--NP33 -Call proc greplay to combine the two graphs */
  /*set up coordinates*/
  %macro setxy(topy, boty);
    %local topy boty x1 y1 x2 y2;
    %let x1=0;
    %let y1=70.25;
    %let x2=70;
    %let y2=100;
    1/ ulx=&x1 uly=&topy.  urx=&y1 ury=&topy.
       llx=&x1 lly=%eval(&boty.)  lrx=&y1 lry=%eval(&boty.)
    2/ ulx=&x2 uly=&topy.  urx=&y2 ury=&topy.
       llx=&x2 lly=%eval(&boty.+7)   lrx=&y2 lry=%eval(&boty.+7)
    3/ ulx=&x1 uly=100  urx=100 ury=100
       llx=&x1 lly=0  lrx=100 lry=0
  %mend;

  options orientation=landscape; /*ensures landscape orientation for graphic*/

  goptions reset=all device=&device gsfname=gfileref hsize=9.25in vsize=6in
           horigin=0.88in vorigin=1.25in ftext=&font. ftitle=&font. cback=white
           ctext=black display nocharacters  gsfmode=replace htext=10pt
           htitle=10pt xmax=11 in  ymax = 8.5 in rotate=landscape lfactor=10;


  proc greplay nofs tc=work.&prefix.graphs igout=work.&prefix.graphs;
    tdef conv1x1
    %setxy(topy=&topy., boty = &boty.);
    template conv1x1;
    treplay
    1:lhgraph 
    2:rhgraph
    3:headfoot
    ;
  run;
  quit;

    
     
  /*----------------------------------------------------------------------*/
  /*--NP34 - Call tu_tidyup and delete work datasets */
  %tu_tidyup(glbmac = NONE,RMDSET = &prefix.: );

%MEND;


