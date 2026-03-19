/*-------------------------------------------------------------------------------------------------------------------------+
| Macro Name                   : TD_ISO4
|
| Macro Version                : 3 build 1
| 
| SAS version                  : SAS v8.2
|
| Created By                   : Ian Barretto
|
| Date                         : 26-May-2006
|
| Macro Purpose                : This unit creates an IDSL standard Integrated Safety Outputs
|                                display 'Summary of Exposure to Study Drug'.
|
| Macro Design                 : PROCEDURE STYLE
|
| Input Parameters             :
|
| NAME                 DESCRIPTION                                                         REQ/OPT              DEFAULT
| -------------------------------------------------------------------------------------------------------------------------                   
| ACROSSVAR            Passed to %tu_freq and %tu_sumstatsinrows.                          OPT                  &g_trtcd
|
| ACROSSVARDECODE      Passed to %tu_freq and %tu_sumstatsinrows.                          OPT                  &g_trtgrp
|
| CATINTERVAL          Exposure duration intervals for categorising                        REQ                  20 40 60
|
| CATDESCPREFIX        Label to prefix Duration categories                                 OPT                  (Blank)
|                                                                                                            
| CATDESCSUFFIX        Label to suffix Duration categories                                 OPT                  (Blank)
|
| CENTREVARS           Passed to %tu_list                                                  OPT                  (Blank)
|
| CODEDECODEVARPAIRS   Passed to %tu_freq and %tu_sumstatsinrows.                          OPT                  &g_trtcd 
|
| COLSPACING           Passed to %tu_list                                                  OPT                  2
|
| COLUMNS              Passed to %tu_list                                                  REQ                  tt_avid tt_avnm 
|                                                                                                               tt_svid tt_svnm
|                                                                                                               tt_ac:
|
| COMPUTEBEFOREPAGE   Passed to %tu_list                                                   OPT                  (Blank)
| LINES               
|                     
|
| COMPUTEBEFORE       Passed to %tu_list                                                   OPT                  (Blank)
| PAGEVARS            
|                     
|
| COUNTDISTIN         Passed to %tu_sumstatsinrows.                                        OPT                  &g_centid
| CTWHATVAR                                                                                                     &g_subjid
|
| DSETINDENOM         Passed to %tu_freq.                                                  REQ                  &g_popdata
|
| DSETINNUMER         Input dataset containing data to be counted to obtain                REQ                  ardata.exposure
|                     the numerator.
|
| DURATIONFREQLABEL   Specifies a label for Exposure duration categories                   REQ                  Days on Study Drug
|
| DURATIONSUMSTST     Specifies a label for Exposure duration summary statistics           REQ                  Days on Study Drug
| LABEL
|
| DURATIONYEARSYN     Display Duration in Subject Years Y/N                                REQ                  Y
|
| DURATIONYEARLABEL   Specifies a label for Exposure duration summary statistics           OPT                  Duration of dosing in 
|                                                                                                               Subject Years
|
| EXDURUVAR           Specify a variable which represents the unit of drug                 REQ                  exduru
|                     exposure duration.
|
| EXDURVAR            Specify a variable which represents the drug exposure                REQ                  exdur
|                     duration.
|
| FLOWVARS            Passed to %tu_list                                                   OPT                  tt_avnm
|                                                                                                               tt_svnm
|
| FORMATS             Passed to %tu_list and %tu_sumstatsinrows.                           OPT                  (Blank)
|
| GROUPBYVARPOP       Passed to %tu_freq and %tu_sumstatsinrows.                           OPT                  &g_trtcd
|
| GROUPBYVARSDENOM    Passed to %tu_freq.                                                  OPT                  &g_trtcd
|
| GROUPBYVARSNUMER    Passed to %tu_freq.                                                  OPT                  &g_trtcd
|
| LABELS              Passed to %tu_list                                                   OPT                  tt_svnm="~" tt_avnm="~"
|
| LEFTVARS            Passed to %tu_list                                                   OPT                  (Blank)
|
| NOPRINTVARS         Passed to %tu_list                                                   OPT                  tt_svid
|                                                                                                               tt_avid
|
| NOWIDOWVAR          Passed to %tu_list                                                   OPT                  (Blank)
|
| ORDERVARS           Passed to %tu_list                                                   OPT                  tt_avid tt_avnm 
|                                                                                                               tt_svid tt_svnm
|
| RESULTSTYLE         Passed to %tu_freq.                                                  REQ                  NUMERPCT
|
| RIGHTVARS           Passed to %tu_list                                                   OPT                  (Blank)
|
| SKIPVARS            Passed to %tu_list                                                   OPT                  tt_svnm
|
| STATSDPS            Pass to %tu_sumstatsinrows.                                          OPT                  MEDIAN +1
|                                                                                                               MEAN +1
|                                                                                                               STD +2
|
| STATSLIST           Passed to %tu_sumstatsinrows.                                        REQ                  n mean std 
|                                                                                                               median min max
|
| TOTALDECODE         Passed to %tu_freq.                                                  OPT                  Total
|
| TOTALFORVAR         Passed to %tu_freq.                                                  OPT                  &g_trtcd
|
| TOTALID             Passed to %tu_freq.                                                  OPT                  999
|
| VARSPACING          Passed to %tu_list.                                                  OPT                  (Blank)
|
| WIDTHS              Passed to %tu_list.                                                  OPT                  tt_avnm 20
|                                                                                                               tt_svnm 15
|                                                                                                               tt_ac: 12
|
|---------------------------------------------------------------------------------------------------------------------------                  
|
| Output :        The unit shall optionally produce an output file in plain ASCII text format containing a
|                 report matching the requirements specified as input parameters.The output file shall only 
|                 contain keyboard characters. The output file shall be localised.
|
| Global macro variables created        :
| 
| Macros called :
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_abort
| (@) tu_catsplit
| (@) tu_freq
| (@) tu_list
| (@) tu_sumstatsinrows
| (@) tu_tidyup
| (@) tu_valparms
|              
|-------------------------------------------------------------------------------------------------------------------------
| Change Log :
|
| Modified By : Ian Barretto
| Date of Modification : 12May06
| New Version Number : n/a
| Modification ID : n/a
| Reason For Modification : Place parameter values on one line so that macro can be checked in to HARP
|-------------------------------------------------------------------------------------------------------------------------
| Modified By : Ian Barretto
| Date of Modification : 26May06
| New Version Number : 2 build 1
| Modification ID : 001
| Reason For Modification : Reset G_TRTCD and G_TRTGRP depending on study design
|-------------------------------------------------------------------------------------------------------------------------
| Modified By : Ian Barretto
| Date of Modification : 19Jul06
| New Version Number : 3 build 1
| Modification ID : 002
| Reason For Modification : Allow subsetting on EXDUR variable. Abort macro if conversion to Subject Year not on valid list
+-------------------------------------------------------------------------------------------------------------------------*/
                                 
%macro td_iso4(
  acrossvar              = &g_trtcd                               /* Variable to transpose the data across to make columns of results. This is passed to PROC TRANSPOSE ID statement */
 ,acrossvardecode        = &g_trtgrp                              /* A variable or format used in the construction of labels for the result columns. */
 ,catdescprefix          =                                        /* Label to prefix duration categories */
 ,catdescsuffix          =                                        /* Label to sufix duration categories */
 ,catinterval            = 20 40 60                               /* Exposure duration intervals for categorising */
 ,centrevars             =                                        /* Centre justify variables */
 ,codedecodevarpairs     = &g_trtcd &g_trtgrp                     /* Code and Decode variables in pairs */
 ,colspacing             = 2                                      /* Value for between-column spacing */
 ,columns                = tt_avid tt_avnm tt_svid tt_svnm tt_ac: /* Columns to be included in the listing (plus spanned headers */
 ,computebeforepagelines =                                        /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt : labelvar) */
 ,computebeforepagevars  =                                        /* Names of variables that define the sort order for  Compute Before Page lines */
 ,countdistinctwhatvar   = &g_centid &g_subjid                    /* Variable(s) that contain values to be counted uniquely within any output grouping. Eg &g_subjid */
 ,dsetindenom            = &g_popdata                             /* Input dataset containing data to be counted to obtain the denominator */
 ,dsetinnumer            = ardata.exposure                        /* Input dataset containing demographic data to be counted to obtain the numerator. */
 ,durationfreqlabel      = Days on Study Drug                     /* Display label for Duration of dosing in subject years */
 ,durationsumststlabel   = Days on Study Drug                     /* Display label for Duration of dosing in subject years */
 ,durationyearsyn        = Y                                      /* Display duration in Subject years Y/N  */
 ,durationyearlabel      = Duration of dosing in subject years [1]/* Display label for Duration of dosing in subject years */
 ,exduruvar              = exduru                                 /* Specify a variable which represents the unit of drug exposure duration.*/
 ,exdurvar               = exdur                                  /* Specify a variable which represents the drug exposure duration.*/
 ,flowvars               = tt_avnm tt_svnm                        /* Variables with flow option */
 ,formats                =                                        /* Format specification (valid SAS syntax) */
 ,groupbyvarpop          = &g_trtcd                               /* Variables to group by when counting big N */
 ,groupbyvarsdenom       = &g_trtcd                               /* Variables in DSETINDENOM to group the data by when counting to obtain the denominator */
 ,groupbyvarsnumer       = &g_trtcd                               /* Variables in DSETINNUMER to group the data by when counting to obtain the numerator */
 ,labels                 = tt_svnm="~" tt_avnm="~"                /* Label definitions (var=var label) */
 ,leftvars               =                                        /* Left justify variables */
 ,noprintvars            = tt_svid tt_avid                        /* No print variables, used to order the display */
 ,nowidowvar             =                                        /* List of variables whose values must be kept together on a page */
 ,ordervars              = tt_avid tt_avnm tt_svid tt_svnm        /* Order variables */
 ,resultstyle            = numerpct                               /* The appearance style of the result columns that will be displayed in the report. */
 ,rightvars              =                                        /* Right justify variables */
 ,skipvars               = tt_avnm                                /* Variables whose change in value causes the display to skip a line */
 ,statsdps               = MEDIAN +1 MEAN +1 STD +2               /* Number of decimal places of summary statistical results */
 ,statslist              = n mean std median min max              /* Specifies a list of summary statistics to be produced. */
 ,totaldecode            = Total                                  /* Label for the total result column. Usually the text Total */
 ,totalforvar            = &g_trtcd                               /* Variable for which a total is required, usually trtcd */
 ,totalid                = 999                                    /* Value used to populate the variable specified in ACROSSVAR on data that represents the overall total for the ACROSSVAR variable */
 ,varspacing             =                                        /* Column spacing for individual variables */
 ,widths                 = tt_avnm 20 tt_svnm 15 tt_ac: 12        /* Column widths */
  );

 /*----------------------------------------------------------------------*/
 /* Change001 - Reset G_TRTCD and G_TRTGRP depending on study design     */
 /*----------------------------------------------------------------------*/

 %if &g_stype eq XO %then %do;
   %let g_trtcd=ptrtcd;
   %let g_trtgrp=ptrtgrp;
      
   %if &g_trtvar eq A %then %do;
     %let g_trtcd=patrtcd;
     %let g_trtgrp=patrtgrp;
   %end;
 %end;

 /*----------------------------------------------------------------------*/
 /* NP01 - Write details of macro start to log                           */
 /*----------------------------------------------------------------------*/

 %local MacroVersion macroname;
 %let macroname = &sysmacroname.;
 %let MacroVersion = 3 build 1;
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals();

 /*----------------------------------------------------------------------*/
 /* NP02.  Assign prefix for work datasets                                      */
 /*----------------------------------------------------------------------*/
 %local prefix;
 %let prefix = _iso4;

 /*----------------------------------------------------------------------*/
 /*                        PARAMETER VALIDATION                          */
 /*----------------------------------------------------------------------*/
     
 /*----------------------------------------------------------------------*/
 /*-- NP03 - Perform Paramter validation*/
 /*-- set up a macro variable to hold the pv_abort flag*/
 /*----------------------------------------------------------------------*/
 
 %local pv_abort;
 %let pv_abort = 0;

 /*----------------------------------------------------------------------*/
 /*  PV01 - Check that CATINTERVAL is not blank                          */
 /*----------------------------------------------------------------------*/
 
 %if %nrbquote(&catinterval) eq %then %do;
   %put %str(RTE)RROR: &sysmacroname: The parameter CATINTERVAL is required.;
   %let pv_abort=1;
 %end;

 /*----------------------------------------------------------------------*/
 /*  PV02 - Check that DSETINNUMER is an existing dataset                */
 /*----------------------------------------------------------------------*/

  %tu_valparms( macroname = &macroname.
               ,chktype   = dsetExists
               ,pv_dsetin = dsetinnumer);
 
 /*----------------------------------------------------------------------*/
 /*  PV03 - Check that DURATIONSUMSTSTLABEL is not blank                 */
 /*----------------------------------------------------------------------*/
 
 %if %nrbquote(&durationsumststlabel) eq %then %do;
   %put %str(RTE)RROR: &sysmacroname: The parameter DURATIONSUMSTSTLABEL is required.;
   %let pv_abort=1;
 %end;

 /*----------------------------------------------------------------------*/
 /*  PV04 - Check that DURATIONFREQLABEL is not blank                    */
 /*----------------------------------------------------------------------*/
 
 %if %nrbquote(&durationfreqlabel) eq %then %do;
   %put %str(RTE)RROR: &sysmacroname: The parameter DURATIONFREQLABEL is required.;
   %let pv_abort=1;
 %end;
 
 /*----------------------------------------------------------------------*/
 /*  PV05 - Check that DURATIONYEARSYN is Y/N                            */
 /*----------------------------------------------------------------------*/
 
 %tu_valparms(macroname = &macroname, chktype=isoneof, 
              pv_varsin = durationyearsyn,  
              valuelist = Y N);
              
 /*----------------------------------------------------------------------*/
 /* NP04 - Complete parameter validation                                 */
 /*----------------------------------------------------------------------*/

 %if %eval(&g_abort. + &pv_abort.) gt 0 %then %do;
   %put %str(RTE)RROR: &macroname: Macro has failed parameter validation check for reasons stated with %str(RTE)RRORs above;
   %tu_abort(option=force);
 %end;

 /*----------------------------------------------------------------------*/
 /*                        NORMAL PROCESSING                             */
 /*----------------------------------------------------------------------*/

 /*----------------------------------------------------------------------*/
 /* NP05 - If &g_analy_disp equals D,go to 'Create Display'              */
 /*----------------------------------------------------------------------*/
 
 %if %nrbquote(&g_analy_disp) eq D %then %do;
   %goto CreateDisplay;
 %end;

 /*----------------------------------------------------------------------*/
 /* NP06 - Calculate summary statistics for exposure to study drug       */
 /*----------------------------------------------------------------------*/
 
 %tu_sumstatsinrows(
     acrosscolvarprefix       = tt_ac
    ,acrossvar                = &acrossvar
    ,acrossvardecode          = &acrossvardecode
    ,addbignyn                = Y
    ,alignyn                  = Y
    ,analysisvarname          = tt_avnm
    ,analysisvarordervarname  = tt_avid
    ,analysisvars             = &exdurvar
    ,codedecodevarpairs       = &codedecodevarpairs
    ,colspacing               = &colspacing
    ,countdistinctwhatvarpop  = &countdistinctwhatvar
    ,denormyn                 = Y
    ,dsetin                   = &dsetinnumer
    ,dsetout                  = &prefix._sumststout
    ,display                  = N
    ,formats                  = &formats
    ,groupbyvarpop            = &groupbyvarpop
    ,groupbyvarsanaly         = &codedecodevarpairs
    ,resultvarname            = tt_result
    ,statsdps                 = &statsdps
    ,statslist                = &statslist
    ,statslistvarname         = tt_svnm
    ,statslistvarordervarname = tt_svid
    ,totalforvar              = &totalforvar
    ,totaldecode              = &totaldecode
    ,totalid                  = &totalid
    );

 /*----------------------------------------------------------------------*/
 /* NP07 - Add display labels and format dataset                         */
 /*----------------------------------------------------------------------*/

 data &prefix._sumstst;
   length tt_avnm $80;
   set &prefix._sumststout;
   tt_avnm="&durationsumststlabel";
 run;
 
 /*----------------------------------------------------------------------*/
 /* NP08 - Create temporary dataset which is subsetted with withdrawan   */
 /*        subjects prior to categorising                                */
 /*----------------------------------------------------------------------*/

 data &prefix._catin;
   set &dsetinnumer;
 run; 

 /*----------------------------------------------------------------------*/
 /* NP09 - Create Exposure Duration categories                           */
 /*----------------------------------------------------------------------*/
                                       
 %tu_catsplit( 
     descprefix   = &catdescprefix
    ,descsuffix   = &catdescsuffix
    ,dsetin       = &prefix._catin
    ,dsetout      = &prefix._catsplit
    ,fmtout       =
    ,interval     = &catinterval
    ,varout       = durcat
    ,varoutdecode = durcatdecode
    ,varin        = &exdurvar
    );
                 
 /*----------------------------------------------------------------------*/
 /* NP10 - Create frequencies for overall withdrawals for each study     */
 /*----------------------------------------------------------------------*/

 %tu_freq(
     acrosscolvarprefix = tt_ac
    ,acrossvar          = &acrossvar
    ,acrossvardecode    = &acrossvardecode
    ,display            = N
    ,dsetout            = &prefix._durcatfreq
    ,dsetinnumer        = &prefix._catsplit
    ,dsetindenom        = &dsetindenom
    ,groupbyvarsnumer   = &groupbyvarsnumer durcat durcatdecode
    ,groupbyvarsdenom   = &groupbyvarsdenom
    ,completetypesvars  = &g_trtcd
    ,codedecodevarpairs = &g_trtcd &g_trtgrp durcat durcatdecode
    ,denormyn           = Y
    ,addbignyn          = Y
    ,resultstyle        = &resultstyle
    ,groupbyvarpop      = &g_trtcd
    ,totalforvar        = &totalforvar
    ,totalid            = &totalid
    ,totaldecode        = &totaldecode
    ,ordervars          = tt_summarylevel
    ,postsubset         = %str(tt_avid=2)
    ,remsummarypctyn    = N
    ,varsToDenorm       = tt_result
    );

 /*----------------------------------------------------------------------*/
 /* NP11 - Add display labels and format dataset                         */
 /*----------------------------------------------------------------------*/

 data &prefix._catfreq (drop=tt_summarylevel durcat durcatdecode);
   length tt_avid 8 tt_avnm $80 tt_svid 8 tt_svnm $25;
   set &prefix._durcatfreq;
    
   tt_avnm="&durationfreqlabel";
    
   tt_svid=durcat;
   tt_svnm=durcatdecode;
    
 run;

 /*----------------------------------------------------------------------*/
 /* NP12 - Conditionally display exposure to study drug in years         */
 /*----------------------------------------------------------------------*/
 
 %if %upcase(&durationyearsyn) eq Y %then %do;
                        
 /*----------------------------------------------------------------------*/
 /* NP13 - Convert exposure to study drug into YEARS                     */
 /*----------------------------------------------------------------------*/
 
 /*----------------------------------------------------------------------*/
 /* Change  003 - Allow subsetting on EXDUR variable. Abort macro if     */
 /*               conversion to Subject Year not on valid list           */
 /*----------------------------------------------------------------------*/
                  
   %let exp_abort=0;
   
   data &prefix._dsetinnumer;
     set &dsetinnumer;

     if upcase(&exduruvar) eq 'DAYS' then do;
       exdurvar=(&exdurvar*1)/365.25;
     end;
     else if upcase(&exduruvar) eq 'WEEKS' then do;
       exdurvar=(&exdurvar*7)/365.25;
     end;
     else if upcase(&exduruvar) eq 'MONTHS' then do;
       exdurvar=(&exdurvar*30.44)/365.25;
     end;
     else if upcase(&exduruvar) eq 'YEARS' then do;
       exdurvar=(&exdurvar*365.2)/365.25;
     end;
     else do;
       call symput('exp_abort','1');
     end;
   run;
   
   %if &exp_abort. eq 1 %then %do;
     %put %str(RTE)RROR: &macroname: The macro can only convert Days, Weeks or Months to Exposure Years;
     %tu_abort(option=force);
   %end;

 /*----------------------------------------------------------------------*/
 /* NP14 - Calculate overall total for exposure to study drug in Years   */
 /*----------------------------------------------------------------------*/
   %tu_sumstatsinrows(
       acrosscolvarprefix       = tt_ac
      ,acrossvar                = &acrossvar
      ,acrossvardecode          = &acrossvardecode
      ,addbignyn                = Y
      ,alignyn                  = Y
      ,analysisvarname          = tt_avnm
      ,analysisvarordervarname  = tt_avid
      ,analysisvars             = exdurvar
      /*,analysisvars             = &exdurvar*/
      ,codedecodevarpairs       = &codedecodevarpairs
      ,colspacing               = &colspacing
      ,countdistinctwhatvarpop  = &countdistinctwhatvar
      ,denormyn                 = Y
      ,dsetin                   = &prefix._dsetinnumer
      ,dsetout                  = &prefix._sumout
      ,display                  = N
      ,formats                  = &formats
      ,groupbyvarpop            = &groupbyvarpop
      ,groupbyvarsanaly         = &codedecodevarpairs
      ,resultvarname            = tt_result
      ,statsdps                 = sum +1
      ,statslist                = sum
      ,statslistvarname         = tt_svnm
      ,statslistvarordervarname = tt_svid
      ,totalforvar              = &totalforvar
      ,totaldecode              = &totaldecode
      ,totalid                  = &totalid
      );

 /*----------------------------------------------------------------------*/
 /* NP15 - Add display labels and format dataset                         */
 /*----------------------------------------------------------------------*/
   
   data &prefix._sum;
     length tt_avnm $80;
     set &prefix._sumout;
     tt_avid=3;
     tt_avnm="&durationyearlabel";
     tt_svnm='';
   run;
   
 %end; /* End of Exposure in Subject Years */
    
 /*----------------------------------------------------------------------*/
 /* NP16 - Append frequency counts and summary statistics datasets       */
 /*----------------------------------------------------------------------*/
    
 data &prefix._durations;
   set &prefix._catfreq
       &prefix._sumstst
       %if %upcase(&durationyearsyn) eq Y %then %do;
         &prefix._sum
       %end;
       ;
 run;
 
 /*----------------------------------------------------------------------*/
 /* Create final display.                                                */
 /*----------------------------------------------------------------------*/

 %CreateDisplay:

 /*----------------------------------------------------------------------*/
 /* NP17 - If &g_analy_disp equals D reset tu_list input dataset to the  */
 /*        DD dataset                                                    */
 /*----------------------------------------------------------------------*/

 %if %nrbquote(&g_analy_disp) eq D %then
 %do;
     %let dsetinlist=dddata.iso4;
 %end;
 %else %do;
   %let dsetinlist=&prefix._durations;
 %end;

 /*----------------------------------------------------------------------*/
 /* NP18 - Call %tu_list to create final display.                        */
 /*----------------------------------------------------------------------*/
 
 %tu_list(
     centrevars     = &centrevars
    ,columns        = &columns
    ,colspacing     = &colspacing
    ,computebeforepagelines=&computebeforepagelines
    ,computebeforepagevars=&computebeforepagevars
    ,dddatasetlabel = DD dataset for ISO4 table
    ,dsetin         = &dsetinlist
    ,flowvars       = &flowvars
    ,formats        = &formats
    ,getdatayn      = N
    ,labels         = &labels
    ,leftvars       = &leftvars
    ,noprintvars    = &noprintvars
    ,nowidowvar     = &nowidowvar
    ,ordervars      = &ordervars
    ,rightvars      = &rightvars
    ,skipvars       = &skipvars
    ,varspacing     = &varspacing
    ,widths         = &widths
     );

 /*----------------------------------------------------------------------*/
 /* NP19 - Call %tu_tidyup to delete temporary data sets.                */
 /*----------------------------------------------------------------------*/

 %tu_tidyup(
     glbmac=none
    ,rmdset=&prefix:
    );
    
%mend td_iso4;
