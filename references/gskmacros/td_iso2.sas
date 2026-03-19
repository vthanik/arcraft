/*----------------------------------------------------------------------------------------------------------------+
| Macro Name                   : TD_ISO2
|
| Macro Version                : 3 build 1
|
| SAS version                  : SAS v8.2
|
| Created By                   : Ian Barretto
|
| Date                         : 26-May-2006
|
| Macro Purpose                : This unit creates an IDSL standard Integrated Safety Outputs display
|                                'Summary of Withdrawal by Demographic Characteristic by Study'.
|
| Macro Design                 : PROCEDURE STYLE
|
| Input Parameters             :
|
| NAME                     DESCRIPTION                                          REQ/OPT           DEFAULT
| -------------------------------------------------------------------------------------------------------                           
| AGEINTERVAL              Age intervals for categorising                       REQ               65
|
| AGELABELPREFIX           Label to prefix Age categories                       OPT               Age
|
| AGELABELSUFFIX           Label to suffix Age categories                       OPT               years
|
| CENTREVARS               Passed to %tu_list.                                  OPT               
|
| COLSPACING               Passed to %tu_list.                                  OPT               2
|
| COLUMNS                  Passed to %tu_list.                                  REQ               tt_segment
|                                                                                                 rowtext
|                                                                                                 tt_order
|                                                                                                 studyid
|                                                                                                 tt_result:
|
| COMPUTEBEFOREPAGELINES   Passed to %tu_list.                                  OPT               (Blank)
|
| COMPUTEBEFOREPAGEVARS    Passed to %tu_list.                                  OPT               (Blank)
|                                                                             
| DSETINDENOM              Passed to %tu_freq.                                  REQ               &g_popdata
|
| DSETINNUMER              Passed to %tu_freq.                                  REQ               ardata.disposit(where=(dswd='Y'))
|
| FLOWVARS                 Passed to %tu_list.                                  OPT               (Blank)
|
| FORMATS                  Passed to %tu_list.                                  OPT               (Blank)
|
| GROUPBYVARSDENOM         Passed to %tu_freq.                                  OPT               &g_trtcd
|
| GROUPBYVARSNUMER         Passed to %tu_freq.                                  OPT               &g_trtcd
|
| LABELS                   Passed to %tu_list.                                  OPT               rowtext="~"
|                                                                                                 studyid="~"
|
| LEFTVARS                 Passed to %tu_list.                                  OPT               (Blank)
|              
| NOWIDOWVAR               Passed to %tu_list.                                  OPT               rowtext
|
| RESULTSTYLE              Passed to %tu_freq.                                  REQ               NUMERDENOMPCT
|                                                                        
| RIGHTVARS                Passed to %tu_list.                                  OPT               (Blank)
|
| SKIPVARS                 Passed to %tu_list.                                  OPT               rowtext
|
| TLTWITHDRAWLABEL         Specifies a label for Total Withdrawn                REQ               Total withdrawn
|
| TOTALDECODE              Passed to %tu_freq.                                  OPT               Total
|
| TOTALFORVAR              Passed to %tu_freq.                                  OPT               &g_trtcd
|
| TOTALID                  Passed to %tu_freq.                                  OPT               999
|
| VARSPACING               Passed to %tu_list.                                  OPT               (Blank)
|
| WIDTHS                   Passed to %tu_list.                                  OPT               tt_result: 20
|
|------------------------------------------------------------------------------------------------------------------                        
| Output         :        The unit shall optionally produce an output file
|                         in plain ASCII text format containing a report
|                         matching the requirements specified as input parameters.
|                         The output file shall only contain keyboard characters.
|                         The output file shall be localised.
|                         The unit shall store the dataset that forms the foundation
|                         of the data display.
|
| Global macro variables created        :        None
|
| Macros called :
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_abort
| (@) tu_catsplit
| (@) tu_denorm
| (@) tu_freq
| (@) tu_list
| (@) tu_percent
| (@) tu_tidyup
|
|-----------------------------------------------------------------------------------------------------------------
| Change Log : 
|
| Modified By : Ian Barretto 
| Date of Modification : 26-May-2006
| New Version Number : 2 build 1
| Modification ID : 001
| Reason For Modification : Reset G_TRTCD and G_TRTGRP depending on study design
+-----------------------------------------------------------------------------------------------------------------
| Modified By : Ian Barretto 
| Date of Modification : 17-Jul-2006
| New Version Number : 3 build 1
| Modification ID : n/a
| Reason For Modification : Add ROWTEXT as default value to FLOWVARS
+-----------------------------------------------------------------------------------------------------------------*/

%macro td_iso2(
  ageinterval            = 65                             /*Age intervals for categorising*/
 ,agelabelprefix         = Age                            /*Label to prefix Age categories*/
 ,agelabelsuffix         = years                          /*Label to suffix Age categories*/
 ,centrevars             =                                /*Centre justify variables*/
 ,colspacing             = 2                              /*Value for between-column spacing*/
 ,columns                = tt_segment rowtext tt_order studyid tt_result: /*Columns to be included in the listing (plus spanned headers)*/
 ,computebeforepagelines =                                /*Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt : labelvar)*/
 ,computebeforepagevars  =                                /*Names of variables that define the sort order for Compute Before Page lines*/
 ,dsetindenom            = &g_popdata                     /*Input dataset containing data to be counted to obtain the denominator*/
 ,dsetinnumer            = ardata.disposit(where=(dswd='Y')) /*Input dataset containing AE data to be counted to obtain the numerator*/
 ,flowvars               = rowtext                        /*Variables required to flow. i.e. cover more than one line per column*/
 ,formats                =                                /*Format specification (valid SAS syntax)*/
 ,groupbyvarsdenom       = &g_trtcd                       /*Variables in DSETINDENOM to group the data by when counting to obtain the denominator*/
 ,groupbyvarsnumer       = &g_trtcd                       /*Variables in DSETINNUMER to group the data by when counting to obtain the numerator*/
 ,labels                 = rowtext=~ studyid=~            /*Label definitions (var="var label")*/
 ,leftvars               =                                /*Left justify variables*/
 ,nowidowvar             = rowtext                        /*List of variables whose values must be kept together on a page*/
 ,resultstyle            = numerdenompct                  /*The appearance style of the result columns that will be displayed in the report*/
 ,rightvars              =                                /*Right justify variables*/
 ,skipvars               = rowtext                        /*Variables whose change in value causes the display to skip a line*/
 ,tltwithdrawlabel       = Total Withdrawn                /*Label for 'Total withdraw'*/
 ,totaldecode            = Total                          /*Label for the total result column. Usually the text Total*/
 ,totalforvar            = &g_trtcd                       /*Variable for which a total is required, usually trtcd*/
 ,totalid                = 999                            /*Value used to populate the variable specified in ACROSSVAR on data that represents the overall total for the ACROSSVAR variable*/
 ,varspacing             =                                /*Column spacing for individual variables*/
 ,widths                 = tt_result: 20 rowtext 25       /*Column widths*/
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

    %local MacroVersion;
    %let MacroVersion = 3 build 1;
    %include "&g_refdata/tr_putlocals.sas";
    %tu_putglobals();

    /*----------------------------------------------------------------------*/
    /* NP02 - Assign prefix for work datasets                               */
    /*----------------------------------------------------------------------*/
    %local prefix;
    %let prefix = _iso2;

    /*----------------------------------------------------------------------*/
    /*                        PARAMETER VALIDATION                          */
    /*----------------------------------------------------------------------*/

    /*----------------------------------------------------------------------*/
    /* NP03 - Perform Paramter validation                                   */
    /*----------------------------------------------------------------------*/
    /*----------------------------------------------------------------------*/
    /* PV01 - Check that AGEINTERVAL is not blank                           */
    /*----------------------------------------------------------------------*/
    
    %if %nrbquote(&ageinterval) eq %then
    %do;
        %put %str(RTE)RROR: &sysmacroname: The parameter AGEINTERVAL is required.;
        %let g_abort=1;
    %end;

    /*----------------------------------------------------------------------*/
    /* PV02 - Check that TLTWITHDRAWLABEL is not blank                      */
    /*----------------------------------------------------------------------*/
    
    %if %nrbquote(&tltwithdrawlabel) eq %then
    %do;
        %put %str(RTE)RROR: &sysmacroname: The parameter TLTWITHDRAWLABEL is required. ;
        %let g_abort=1;
    %end;
   
    /*----------------------------------------------------------------------*/
    /*- PV03 - Complete parameter validation */
    /*----------------------------------------------------------------------*/

    %if &syserr gt 0 %then
    %do;
        %put RTER%str(ROR): &sysmacroname: Error in SAS;
        %let g_abort=1;
    %end;

    %if &g_abort eq 1 %then %goto MacErr;
    
    /*----------------------------------------------------------------------*/
    /*                          NORMAL PROCESS                              */
    /*----------------------------------------------------------------------*/

    /*----------------------------------------------------------------------*/
    /* NP04 - If &g_analy_disp equals D,go to 'Create Display'              */
    /*----------------------------------------------------------------------*/

    %if %nrbquote(&g_analy_disp) eq D %then
    %do;
        %goto CreateDisplay;
    %end;

    /*----------------------------------------------------------------------*/
    /* NP05 - Create frequencies for overall withdrawals                    */
    /*----------------------------------------------------------------------*/
    
    %tu_freq(display=N,
             dsetout=&prefix._overallfreq,
             dsetinnumer=&dsetinnumer,
             dsetindenom=&dsetindenom,
             groupbyvarsnumer=&groupbyvarsnumer dswd,
             groupbyvarsdenom=&groupbyvarsdenom,
             completetypesvars=&g_trtcd,
             codedecodevarpairs=&g_trtcd &g_trtgrp,              
             denormyn=N,
             addbignyn=Y,
             resultstyle=&resultstyle,
             groupbyvarpop=&g_trtcd,
             totalforvar=&totalforvar,
             totalid=&totalid,
             totaldecode=&totaldecode,
             postsubset=%str(studyid='n';if dswd='Y';tt_order='1';tt_segment=1),
             remsummarypctyn=N
             );

    /*----------------------------------------------------------------------*/
    /* NP06 - Create frequencies for overall withdrawals for each study     */
    /*----------------------------------------------------------------------*/

    %tu_freq(display=N,
             dsetout=&prefix._overallstudyfreq,
             dsetinnumer=&dsetinnumer,
             dsetindenom=&dsetindenom,
             groupbyvarsnumer=&groupbyvarsnumer dswd studyid,
             groupbyvarsdenom=&groupbyvarsdenom studyid,
             completetypesvars=&g_trtcd studyid,
             codedecodevarpairs=&g_trtcd &g_trtgrp,              
             denormyn=N,
             addbignyn=Y,
             resultstyle=&resultstyle,
             groupbyvarpop=&g_trtcd,
             totalforvar=&totalforvar,
             totalid=&totalid,      
             totaldecode=&totaldecode,
             ordervars=dswd tt_summarylevel studyid,
             postsubset=%str(if dswd='Y';tt_order=studyid;tt_segment=1),
             remsummarypctyn=N
             );

    
    /*----------------------------------------------------------------------*/
    /* NP07 - Set labels for overall withdrawals                            */
    /*----------------------------------------------------------------------*/
                
    data &prefix._wdfreq;
      length rowtext $200;
      set &prefix._overallstudyfreq &prefix._overallfreq;
      rowtext="&tltwithdrawlabel";
    run;

    /*----------------------------------------------------------------------*/
    /* NP08 - Create temporary dataset which is subsetted with withdrawan   */
    /*        subjects prior to categorising by Age                         */
    /*----------------------------------------------------------------------*/
    data &prefix._catin;
      set &dsetinnumer;
    run; 

    /*----------------------------------------------------------------------*/
    /* NP09 - Create Age cateories                                          */
    /*----------------------------------------------------------------------*/
                                       
    %tu_catsplit( descprefix=&agelabelprefix
                 ,descsuffix=&agelabelsuffix
                 ,dsetin=&prefix._catin
                 ,dsetout=&prefix._catsplit
                 ,fmtout=
                 ,interval=&ageinterval
                 ,varout=agecat
                 ,varoutdecode=agecatdecode
                 ,varin=age);

    /*----------------------------------------------------------------------*/
    /* NP10 - Create frequencies for overall withdrawals by Age             */
    /*----------------------------------------------------------------------*/

    %tu_freq(display=N,
             dsetout=&prefix._agecatfreq,
             dsetinnumer=&prefix._catsplit,
             dsetindenom=&dsetindenom,
             groupbyvarsnumer=&groupbyvarsnumer agecat,
             groupbyvarsdenom=&groupbyvarsdenom,
             completetypesvars=&g_trtcd,
             codedecodevarpairs=&g_trtcd &g_trtgrp agecat agecatdecode,              
             denormyn=N,
             addbignyn=Y,
             resultstyle=&resultstyle,
             groupbyvarpop=&g_trtcd,
             totalforvar=&totalforvar,
             totalid=&totalid,      
             totaldecode=&totaldecode,
             ordervars=dswd tt_summarylevel,
             postsubset=%str(studyid='n';tt_order='1';tt_segment=2),
             remsummarypctyn=N
             );

    /*----------------------------------------------------------------------*/
    /* NP11 - Create frequencies for withdrawals by Age for each study      */
    /*----------------------------------------------------------------------*/

    %tu_freq(display=N,
             dsetout=&prefix._agecatstudyfreq,
             dsetinnumer=&prefix._catsplit,
             dsetindenom=&dsetindenom,
             groupbyvarsnumer=&groupbyvarsnumer agecat studyid,
             groupbyvarsdenom=&groupbyvarsdenom studyid,
             completetypesvars=&g_trtcd studyid,
             codedecodevarpairs=&g_trtcd &g_trtgrp agecat agecatdecode,              
             denormyn=N,
             addbignyn=Y,
             resultstyle=&resultstyle,
             groupbyvarpop=&g_trtcd,
             totalforvar=&totalforvar,
             totalid=&totalid,      
             totaldecode=&totaldecode,
             ordervars=dswd tt_summarylevel studyid,
             postsubset=%str(tt_order=studyid;tt_segment=2),
             remsummarypctyn=N
             );

    /*----------------------------------------------------------------------*/
    /* NP12 - Set labels for withdrawals by Age categories                  */
    /*----------------------------------------------------------------------*/
                
    data &prefix._agefreq;
      length rowtext $200;
      set &prefix._agecatstudyfreq &prefix._agecatfreq ;
      rowtext=agecatdecode;
    run;

    /*----------------------------------------------------------------------*/
    /* NP13 - Create frequencies for overall withdrawals by Sex             */
    /*----------------------------------------------------------------------*/

    %tu_freq(display=N,
             dsetout=&prefix._sexfreq,
             dsetinnumer=&dsetinnumer,
             dsetindenom=&dsetindenom,
             groupbyvarsnumer=&groupbyvarsnumer sex,
             groupbyvarsdenom=&groupbyvarsdenom,
             completetypesvars=&g_trtcd,
             codedecodevarpairs=&g_trtcd &g_trtgrp,              
             denormyn=N,
             addbignyn=Y,
             resultstyle=&resultstyle,
             groupbyvarpop=&g_trtcd,
             totalforvar=&totalforvar,
             totalid=&totalid,      
             totaldecode=&totaldecode,
             ordervars=dswd tt_summarylevel,
             postsubset=%str(studyid='n';tt_order='1';tt_segment=3),
             remsummarypctyn=N
             );

    /*----------------------------------------------------------------------*/
    /* NP14 - Create frequencies for withdrawals by Sex for each study      */
    /*----------------------------------------------------------------------*/

    %tu_freq(display=N,
             dsetout=&prefix._sexstudyfreq,
             dsetinnumer=&dsetinnumer,
             dsetindenom=&dsetindenom,
             groupbyvarsnumer=&groupbyvarsnumer sex studyid,
             groupbyvarsdenom=&groupbyvarsdenom studyid,
             completetypesvars=&g_trtcd studyid,
             codedecodevarpairs=&g_trtcd &g_trtgrp,
             denormyn=N,
             addbignyn=Y,
             resultstyle=&resultstyle,
             groupbyvarpop=&g_trtcd,
             totalforvar=&totalforvar,
             totalid=&totalid,      
             totaldecode=&totaldecode,
             ordervars=dswd tt_summarylevel studyid,
             postsubset=%str(tt_order=studyid;tt_segment=3),
             remsummarypctyn=N
             );

    /*----------------------------------------------------------------------*/
    /* NP15 - Set labels for withdrawals by Sex                             */
    /*----------------------------------------------------------------------*/
                
    data &prefix._sexfreq;
      length rowtext $200;
      set &prefix._sexstudyfreq &prefix._sexfreq ;
      rowtext=put(sex,$sex.);
    run;

    /*----------------------------------------------------------------------*/
    /* NP16 - Create frequencies for overall withdrawals by Race            */
    /*----------------------------------------------------------------------*/

    %tu_freq(display=N,
             dsetout=&prefix._racefreq,
             dsetinnumer=&dsetinnumer,
             dsetindenom=&dsetindenom,
             groupbyvarsnumer=&groupbyvarsnumer racecd,
             groupbyvarsdenom=&groupbyvarsdenom,
             completetypesvars=&g_trtcd,
             codedecodevarpairs=&g_trtcd &g_trtgrp racecd race,              
             denormyn=N,
             addbignyn=Y,
             resultstyle=&resultstyle,
             groupbyvarpop=&g_trtcd,
             totalforvar=&totalforvar,
             totalid=&totalid,      
             totaldecode=&totaldecode,
             ordervars=dswd tt_summarylevel,
             postsubset=%str(studyid='n';tt_order='1';tt_segment=4),
             remsummarypctyn=N
             );
             
    /*----------------------------------------------------------------------*/
    /* NP17 - Create frequencies for withdrawals by Race for each study     */
    /*----------------------------------------------------------------------*/

    %tu_freq(display=N,
             dsetout=&prefix._racestudyfreq,
             dsetinnumer=&dsetinnumer,
             dsetindenom=&dsetindenom,
             groupbyvarsnumer=&groupbyvarsnumer racecd studyid,
             groupbyvarsdenom=&groupbyvarsdenom studyid,
             completetypesvars=&g_trtcd studyid,
             codedecodevarpairs=&g_trtcd &g_trtgrp racecd race,
             denormyn=N,
             addbignyn=Y,
             resultstyle=&resultstyle,
             groupbyvarpop=&g_trtcd,
             totalforvar=&totalforvar,
             totalid=&totalid,      
             totaldecode=&totaldecode,
             ordervars=dswd tt_summarylevel studyid,
             postsubset=%str(tt_order=studyid;tt_segment=4),
             remsummarypctyn=N
             );

    /*----------------------------------------------------------------------*/
    /* NP18 - Set labels for withdrawals by Race                            */
    /*----------------------------------------------------------------------*/
                
    data &prefix._racefreq;
      length rowtext $200;
      set &prefix._racestudyfreq &prefix._racefreq ;
      rowtext=race;
    run;

    /*----------------------------------------------------------------------*/
    /* NP19 - Append all frequency counts                                   */
    /*----------------------------------------------------------------------*/

    data &prefix._wddata;
      set &prefix._wdfreq &prefix._agefreq &prefix._sexfreq &prefix._racefreq;
    run;
    
    /*----------------------------------------------------------------------*/
    /* NP20 - Split withdrawal frequency data into numerator and demoninator*/
    /*        datasets ready for percentage calculations                    */
    /*----------------------------------------------------------------------*/
     
    data &prefix._numer 
        (keep=studyid &g_trtcd &g_trtgrp tt_segment tt_order rowtext tt_bnnm tt_numercnt);
      set &prefix._wddata;
    run;
    
    data &prefix._denom 
        (keep=studyid &g_trtcd &g_trtgrp tt_segment tt_order rowtext tt_bnnm tt_denomcnt);
      set &prefix._wddata;
    run;

    /*----------------------------------------------------------------------*/
    /* NP21 - Calculate percentages of withdrawals by study and reason for  */
    /*        withdrawal                                                    */
    /*----------------------------------------------------------------------*/
    
    %tu_percent(dsetinNumer=&prefix._numer , 
                dsetinDenom=&prefix._denom ,          
                numerCntVar=tt_numercnt ,        
                denomCntVar=tt_denomcnt ,        
                mergeVars  =tt_segment tt_order &g_trtcd &g_trtgrp rowtext tt_bnnm,        
                pctDps     =0 ,       
                resultStyle=&resultstyle,
                dsetout    =&prefix._percent 
                );
    
    /*----------------------------------------------------------------------*/
    /* NP22 - Create label variable holding Big N value for each treatment  */
    /*        group                                                         */
    /*----------------------------------------------------------------------*/

    data &prefix._percentbign;
      set &prefix._percent;
      acrossvarbign=trim(left(&g_trtgrp))||"~(N="||trim(left(tt_bnnm))||")"; 
    run;    
    
    /*----------------------------------------------------------------------*/
    /* NP23 - Denormalise data to create treatment groups as columns        */
    /*----------------------------------------------------------------------*/
    
    %tu_denorm(dsetin=&prefix._percentbign,
               dsetout=&prefix._denorm,  
               varstodenorm=tt_result tt_pct tt_bnnm,
               acrossvar= &g_trtcd,
               acrossvarlabel=acrossvarbign,
               groupbyvars=tt_segment rowtext tt_order studyid);
    
    /*----------------------------------------------------------------------*/
    /* Create final data display                                            */
    /*----------------------------------------------------------------------*/

    %CreateDisplay:
    
    /*----------------------------------------------------------------------*/
    /* NP24 - If &g_analy_disp equals D reset tu_list input dataset to be   */
    /*        the DD dataset                                                */
    /*----------------------------------------------------------------------*/

    %if %nrbquote(&g_analy_disp) eq D %then
    %do;
      %let dsetinlist=dddata.iso2;
    %end;
    %else %do;
      %let dsetinlist=&prefix._denorm;
    %end;

    /*----------------------------------------------------------------------*/
    /* NP25 - Call %tu_list to create final display.                        */
    /*----------------------------------------------------------------------*/
        
    %tu_list( centrevars=&centrevars
             ,colspacing=&colspacing
             ,columns=&columns
             ,computebeforepagelines=&computebeforepagelines
             ,computebeforepagevars=&computebeforepagevars
             ,dsetin=&dsetinlist
             ,flowvars=&flowvars
             ,formats=&formats
             ,getdatayn=N     
             ,labels=&labels
             ,leftvars=&leftvars
             ,ordervars=tt_segment rowtext tt_order studyid
             ,noprintvars=tt_segment tt_order
             ,nowidowvar=&nowidowvar
             ,skipvars=&skipvars
             ,rightvars=&rightvars
             ,varspacing=&varspacing
             ,widths=&widths
             );

    
    %goto Endmac;
   
%MacErr:

    %let g_abort=1;
    %tu_abort(option=force);

%EndMac:

    /*----------------------------------------------------------------------*/
    /* NP26 - Call %tu_tidyup to delete temporary data sets.                */
    /*----------------------------------------------------------------------*/

    %tu_tidyup(glbmac=none,
               rmdset=&prefix:
               );

%mend td_iso2;
