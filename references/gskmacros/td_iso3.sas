/*----------------------------------------------------------------------------------------------------------------+
| Macro Name                   : TD_ISO3
|
| Macro Version                : 2 build 1
|
| SAS version                  : SAS v8.2
|
| Created By                   : Ian Barretto
|
| Date                         : 26-May-2006
|
| Macro Purpose                : This unit creates an IDSL standard Integrated Safety Outputs
|                                display 'Summary of Reasons for Withdrawal by Study'.
|
| Macro Design                 : PROCEDURE STYLE
|
| Input Parameters             :
|
| NAME                     DESCRIPTION                                          REQ/OPT           DEFAULT
| -------------------------------------------------------------------------------------------------------                           
| CENTREVARS               Passed to %tu_list.                                  OPT               
|
| COLSPACING               Passed to %tu_list.                                  OPT               2
|
| COLUMNS                  Passed to %tu_list.                                  REQ               %nrstr(
|                                                                                                 tt_segment
|                                                                                                 wdtext
|                                                                                                 dsreascd
|                                                                                                 dsreas
|                                                                                                 tt_order
|                                                                                                 studyid
|                                                                                                 tt_result:)
|
| COMPUTEBEFOREPAGELINES   Passed to %tu_list.                                  OPT               (Blank)
|
| COMPUTEBEFOREPAGEVARS    Passed to %tu_list.                                  OPT               (Blank)
|                                                                             
| DSETINDENOM              Passed to %tu_freq.                                  REQ               &g_popdata
|
| DSETINNUMER              Passed to %tu_freq.                                  REQ               ardata.disposit(where=(dswd='Y'))
|
| DSREASCDVAR              Specifies a variable with values which specify the   REQ               dsreascd
|                          coded reason for withdrawal
|
| DSREASVAR                Specifies a variable with values which specify the   REQ               dsreas
|                          decoded reason for withdrawal
|
| FLOWVARS                 Passed to %tu_list.                                  OPT               %nrstr(&dsreasvar)
|
| FORMATS                  Passed to %tu_list.                                  OPT               (Blank)
|
| GROUPBYVARSDENOM         Passed to %tu_freq.                                  OPT               &g_trtcd
|
| GROUPBYVARSNUMER         Passed to %tu_freq.                                  OPT               %nrstr(&g_trtcd
|                                                                                                 dsreascd
|                                                                                                 dsreas)
|
| LABELS                   Passed to %tu_list.                                  OPT               %nrstr(dsreas="~"
|                                                                                                 studyid="~")
|
| LEFTVARS                 Passed to %tu_list.                                  OPT               (Blank)
|              
| NOWIDOWVAR               Passed to %tu_list.                                  OPT               %nrstr(dsreas)
|
| REASWITHDRAWLABEL        Specifies a label for Reason for Withdrawal          REQ               Reason for withdrawal
|
| RESULTSTYLE              Passed to %tu_freq.                                  REQ               NUMERDENOMPCT
|
| RIGHTVARS                Passed to %tu_list.                                  OPT               (Blank)
|
| SKIPVARS                 Passed to %tu_list.                                  OPT               %nrstr(dsreascd)
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
| WIDTHS                   Passed to %tu_list.                                  OPT               %nrstr(tt_result: 20
|                                                                                                 wdtext 25  
|                                                                                                 &dsreasvar 25)
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
| (@) tu_denorm
| (@) tu_freq
| (@) tu_list
| (@) tu_percent
| (@) tu_tidyup
| (@) tu_valparms
| (@) tu_words
|
|-----------------------------------------------------------------------------------------------------------------
| Change Log :
|
| Modified By : Ian Barretto
| Date of Modification : 26-May-2006
| New Version Number : 2 build 1
| Modification ID : 001
| Reason For Modification : Reset G_TRTCD and G_TRTGRP depending on study design
+-----------------------------------------------------------------------------------------------------------------*/

%macro td_iso3(
  centrevars             =                                /*Centre justify variables*/
 ,colspacing             = 2                              /*Value for between-column spacing*/
 ,columns                = %nrstr(tt_segment wdtext &dsreascdvar &dsreasvar tt_order studyid tt_result:) /*Columns to be included in the listing (plus spanned headers)*/
 ,computebeforepagelines =                                /*Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt : labelvar)*/
 ,computebeforepagevars  =                                /*Names of variables that define the sort order for Compute Before Page lines*/
 ,dsetindenom            = &g_popdata                     /*Input dataset containing data to be counted to obtain the denominator*/
 ,dsetinnumer            = ardata.disposit(where=(dswd='Y')) /*Input dataset containing AE data to be counted to obtain the numerator*/
 ,dsreascdvar            = dsreascd                       /*Variable which specifies coded 'reason for withdrawal'*/
 ,dsreasvar              = dsreas                         /*Variable which specifies decoded 'reason for withdrawal'*/
 ,flowvars               = %nrstr(&dsreasvar)             /*Variables required to flow. i.e. cover more than one line per column*/
 ,formats                =                                /*Format specification (valid SAS syntax)*/
 ,groupbyvarsdenom       = &g_trtcd                       /*Variables in DSETINDENOM to group the data by when counting to obtain the denominator*/
 ,groupbyvarsnumer       = %nrstr(&g_trtcd &dsreascdvar &dsreasvar) /*Variables in DSETINNUMER to group the data by when counting to obtain the numerator*/
 ,labels                 = %nrstr(&dsreasvar=~ studyid=~) /*Label definitions (var="var label")*/
 ,leftvars               =                                /*Left justify variables*/
 ,nowidowvar             = %nrstr(&dsreasvar)             /*List of variables whose values must be kept together on a page*/
 ,reaswithdrawlabel      = Reason for Withdrawal          /*Label for 'Total withdraw'*/
 ,resultstyle            = numerdenompct                  /*The appearance style of the result columns that will be displayed in the report*/
 ,rightvars              =                                /*Right justify variables*/
 ,skipvars               = %nrstr(&dsreascdvar)           /*Variables whose change in value causes the display to skip a line*/
 ,tltwithdrawlabel       = Total withdrawn                /*Label for 'Total withdraw'*/
 ,totaldecode            = Total                          /*Label for the total result column. Usually the text Total*/
 ,totalforvar            = &g_trtcd                       /*Variable for which a total is required, usually trtcd*/
 ,totalid                = 999                            /*Value used to populate the variable specified in ACROSSVAR on data that represents the overall total for the ACROSSVAR variable*/
 ,varspacing             =                                /*Column spacing for individual variables*/
 ,widths                 = %nrstr(tt_result: 20 wdtext 25 &dsreasvar 25) /*Column widths*/
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
    /* NP01/02 - Write details of macro start to log                        */
    /*----------------------------------------------------------------------*/

    %local MacroVersion macroname;
    %let MacroVersion = 2 build 1;
    %let macroname = &sysmacroname.;
    %include "&g_refdata/tr_putlocals.sas";
    %tu_putglobals();

    /*----------------------------------------------------------------------*/
    /* NP03 - Assign prefix for work datasets                               */
    /*----------------------------------------------------------------------*/
    %local prefix;
    %let prefix = _iso3;

    /*----------------------------------------------------------------------*/
    /*                  PARAMETER VALIDATION                                */
    /*----------------------------------------------------------------------*/

    /*----------------------------------------------------------------------*/
    /*-- NP04 - Perform Paramter validation*/
    /*-- set up a macro variable to hold the pv_abort flag*/
    /*----------------------------------------------------------------------*/
    %local pv_abort;
    %let pv_abort = 0;

    /*----------------------------------------------------------------------*/
    /*  PV01 - Check that DSETINDENON is an existing dataset                */
    /*----------------------------------------------------------------------*/

    %tu_valparms( macroname = &macroname.
                 ,chktype   = dsetExists
                 ,pv_dsetin = dsetindenom);

    /*----------------------------------------------------------------------*/
    /*  PV02 - Check that DSETINNUMER is an existing dataset                */
    /*----------------------------------------------------------------------*/
    
    %if %nrbquote(&dsetinnumer) ne %then %do;
      %let temp_dsetinnumer=%scan(&dsetinnumer,1);
      
      %if %tu_words(&dsetinnumer,delim=%str(.)) gt 1 %then %do; 
        %let dsetpart=%scan(&dsetinnumer,2);
        %let temp_dsetinnumer=&temp_dsetinnumer..&dsetpart;
      %end;
      
      %tu_valparms( macroname = &macroname.
                   ,chktype   = dsetExists
                   ,pv_dsetin = temp_dsetinnumer);
    %end;

    /*----------------------------------------------------------------------*/
    /*  PV03/04 - Check that DSREASCDVAR and DSREASVAR exist in DSETINNUMER */
    /*----------------------------------------------------------------------*/

    %tu_valparms( macroname = &macroname.
                 ,chktype   = varExists
                 ,pv_dsetin = temp_dsetinnumer
                 ,pv_varsin = dsreascdvar);
 
    %tu_valparms( macroname = &macroname.
                 ,chktype   = varExists
                 ,pv_dsetin = temp_dsetinnumer
                 ,pv_varsin = dsreasvar);

    /*----------------------------------------------------------------------*/
    /*  PV05 - Check that REASWITHDRAWLABEL is not blank                    */
    /*----------------------------------------------------------------------*/
    
    %if %nrbquote(&reaswithdrawlabel) eq %then
    %do;
        %put %str(RTE)RROR: &sysmacroname: The parameter REASWITHDRAWLABEL is required. ;
        %let pv_abort=1;
    %end;
    
    /*----------------------------------------------------------------------*/
    /*  PV06 - Check that TLTWITHDRAWLABEL is not blank                     */
    /*----------------------------------------------------------------------*/

    %if %nrbquote(&tltwithdrawlabel) eq %then
    %do;
        %put %str(RTE)RROR: &sysmacroname: The parameter TLTWITHDRAWLABEL is required. ;
        %let pv_abort=1;
    %end;

    /*----------------------------------------------------------------------*/
    /*- PV07 - Complete parameter validation */
    /*----------------------------------------------------------------------*/
    %if %eval(&g_abort. + &pv_abort.) gt 0 %then %do;
      %put %str(RTE)RROR: &macroname: Macro has failed parameter validation check for reasons stated with %str(RTE)RRORs above;
      %tu_abort(option=force);
    %end;

    /*----------------------------------------------------------------------*/
    /*                          NORMAL PROCESS                              */
    /*----------------------------------------------------------------------*/

    /*----------------------------------------------------------------------*/
    /* NP05 - If &g_analy_disp equals D,go to 'Create Display'              */
    /*----------------------------------------------------------------------*/

    %if %nrbquote(&g_analy_disp) eq D %then
    %do;
        %goto CreateDisplay;
    %end;

    /*----------------------------------------------------------------------*/
    /* NP06 - Create frequencies for reason for withdrawal for each study */
    /*----------------------------------------------------------------------*/
    
    %tu_freq(display=N,
             dsetout=&prefix._wdreasonstudyfreq,
             dsetinnumer=&dsetinnumer,
             dsetindenom=&dsetindenom,
             groupbyvarsnumer=%unquote(&groupbyvarsnumer) studyid,
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
             postsubset=%str(tt_order=studyid; tt_segment=2),
             remsummarypctyn=N
             );
    
    /*----------------------------------------------------------------------*/
    /* NP07 - Create frequencies for reason for withdrawal */
    /*----------------------------------------------------------------------*/
        
    %tu_freq(display=N,
             dsetout=&prefix._wdreasonfreq,
             dsetinnumer=&dsetinnumer,
             dsetindenom=&dsetindenom,
             groupbyvarsnumer=%unquote(&groupbyvarsnumer),
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
             postsubset=%str(studyid='n';tt_order='1'; tt_segment=2),
             remsummarypctyn=N
             );
    
    /*----------------------------------------------------------------------*/
    /* NP08 - Set labels for reason for withdrawals */
    /*----------------------------------------------------------------------*/
   
    data &prefix._reasonfreq;
      set &prefix._wdreasonstudyfreq &prefix._wdreasonfreq;
      length wdtext $80;
      wdtext="&reaswithdrawlabel";
    run;

    /*----------------------------------------------------------------------*/
    /* NP09 - Create frequencies for overall withdrawals for each study */
    /*----------------------------------------------------------------------*/

    %tu_freq(display=N,
             dsetout=&prefix._overallstudyfreq,
             dsetinnumer=&dsetinnumer,
             dsetindenom=&dsetindenom,
             groupbyvarsnumer=&g_trtcd dswd studyid,
             groupbyvarsdenom=&g_trtcd studyid,
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
    /* NP10 - Create frequencies for overall withdrawals */
    /*----------------------------------------------------------------------*/
    
    %tu_freq(display=N,
             dsetout=&prefix._overallfreq,
             dsetinnumer=&dsetinnumer,
             dsetindenom=&dsetindenom,
             groupbyvarsnumer=&g_trtcd dswd,
             groupbyvarsdenom=&g_trtcd,
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
    /* NP11 - Set labels for overall withdrawals */
    /*----------------------------------------------------------------------*/

    data &prefix._wdfreq;
      length &dsreasvar $200;
      set &prefix._overallstudyfreq &prefix._overallfreq;
      length wdtext $80;
      wdtext="&tltwithdrawlabel";
      &dsreasvar='';
    run;
    
    /*----------------------------------------------------------------------*/
    /* NP12 - Append frequency counts for overall and reasons for withdrawal */
    /*----------------------------------------------------------------------*/

    data &prefix._wddata;
      set &prefix._wdfreq &prefix._reasonfreq;
    run;
    
    /*----------------------------------------------------------------------*/
    /* NP13 - Split withdrawal frequency data into numerator and demoninator */
    /*        datasets ready for percentage calculations                    */
    /*----------------------------------------------------------------------*/
     
    data &prefix._numer 
         (keep=studyid &g_trtcd &g_trtgrp tt_segment tt_order wdtext &dsreascdvar &dsreasvar tt_bnnm tt_numercnt);
      set &prefix._wddata;
    run;
    
    data &prefix._denom 
        (keep=studyid &g_trtcd &g_trtgrp tt_segment tt_order wdtext &dsreascdvar &dsreasvar tt_bnnm tt_denomcnt);
      set &prefix._wddata;
    run;

    /*----------------------------------------------------------------------*/
    /* NP14 - Calculate percentages of withdrawals by study and reason for  */
    /*        withdrawal                                                    */
    /*----------------------------------------------------------------------*/
    
    %tu_percent(dsetinNumer=&prefix._numer , 
                dsetinDenom=&prefix._denom ,          
                numerCntVar=tt_numercnt ,        
                denomCntVar=tt_denomcnt ,        
                mergeVars  =tt_segment tt_order &g_trtcd &g_trtgrp &dsreascdvar &dsreasvar tt_bnnm,        
                pctDps     =0 ,       
                resultStyle=numerdenomPct ,
                dsetout    = &prefix._percent 
                );
    
    /*----------------------------------------------------------------------*/
    /* NP15 - Create label variable holding Big N value for each treatment  */
    /*        group                                                         */
    /*----------------------------------------------------------------------*/

    data &prefix._percentbign;
      set &prefix._percent;
      acrossvarbign=trim(left(&g_trtgrp))||"~(N="||trim(left(tt_bnnm))||")"; 
    run;    
    
    /*----------------------------------------------------------------------*/
    /* NP16 - Denormalise data to create treatment groups as columns        */
    /*----------------------------------------------------------------------*/
    
    %tu_denorm(dsetin=&prefix._percentbign,
               dsetout=&prefix._denorm,  
               varstodenorm=tt_result tt_pct tt_bnnm,
               acrossvar= &g_trtcd,
               acrossvarlabel= acrossvarbign,
               groupbyvars=tt_segment wdtext tt_order studyid &dsreascdvar &dsreasvar);
    
    
    /*----------------------------------------------------------------------*/
    /*  Create final display. */
    /*----------------------------------------------------------------------*/

    %CreateDisplay:

    /*----------------------------------------------------------------------*/
    /* NP17 - If &g_analy_disp equals D reset tu_list input dataset to the  */
    /*        DD dataset                                                    */
    /*----------------------------------------------------------------------*/

    %if %nrbquote(&g_analy_disp) eq D %then
    %do;
        %let dsetinlist=dddata.iso3;
    %end;
    %else %do;
      %let dsetinlist=&prefix._denorm;
    %end;
    
    /*----------------------------------------------------------------------*/
    /* NP18 - Create final display. */
    /*----------------------------------------------------------------------*/
    
    %tu_list( centrevars=&centrevars
             ,columns=%unquote(&columns)
             ,colspacing=&colspacing
             ,computebeforepagelines=&computebeforepagelines
             ,computebeforepagevars=&computebeforepagevars
             ,dsetin=&dsetinlist
             ,flowvars=%unquote(&flowvars)
             ,formats=&formats
             ,getdatayn=N
             ,labels=%unquote(&labels)
             ,leftvars=&leftvars
             ,noprintvars=tt_segment tt_order &dsreascdvar
             ,nowidowvar=%unquote(&nowidowvar)
             ,ordervars=tt_segment &dsreascdvar &dsreasvar tt_order studyid
             ,rightvars=&rightvars
             ,sharecolvars=wdtext &dsreasvar
             ,skipvars=%unquote(&skipvars)
             ,varspacing=&varspacing
             ,widths=%unquote(&widths)
             );
     
    
    %goto Endmac;
   

%EndMac:

    /*----------------------------------------------------------------------*/
    /* NP19 - Call %tu_tidyup to delete temporary data sets.                */
    /*----------------------------------------------------------------------*/

    %tu_tidyup(
        glbmac=none,
        rmdset=&prefix:
        );

%mend td_iso3;
