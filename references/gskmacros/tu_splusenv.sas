/*--------------------------------------------------------------------------+
| Macro Name    : tu_splusenv.sas
|
| Macro Version : 2 build 1
|
| SAS version   : SAS v8.2
|
| Created By    : Elaine Liu
|
| Date          : 17-Jan-2007
|
| Macro Purpose : Call splusenv macro to specify where to place splus script
|                 files and also pass in HARP headers and footer.
|
| Macro Design  : Procedure style
|
| Input Parameters :
|
| NAME                DESCRIPTION                                 REQ/OPT  DEFAULT
|
| USEODS              Use SASs output delivery system              Req     0
| ODSFILEFORMAT       ODS File Format                              Opt     Blank
| REMOVESPLUSSCRIPT   S+ script generated in refdata dir           Req     0
|                     is removed following execution
| LINEWIDTH           Width (in chars) of an output page           Req     108
| PAGELENGTH          Length (in lines) of an output page          Req     43
| PLOTWIDTH           Plot width in inches                         Req     9
| PLOTHEIGHT          Plot height in inches                        Req     6
| PLOTMARGINTOP       Plot top margin in inches                    Req     0.1
| PLOTMARGINBOTTOM    Plot bottom margin in inches                 Req     0.1
| PLOTMARGINLEFT      Plot left margin in inches                   Req     0.1
| PLOTMARGINRIGHT     Plot right margin in inches                  Req     0.1
| POINTSIZE           Title and Footnote point size                Req     10
| XAXISLABELSIZE      Point size for X axis and tick mark labels   Req     10
| YAXISLABELSIZE      Point size for Y axis and tick mark labels   Req     10
| ZAXISLABELSIZE      Point size for Z axis and tick mark labels   Req     10
| SOURCENAME          Filename passed to sourcecode.sas            Opt     Blank
| SOURCELOCATION      File location path passed to sourcecode.sas  Opt     Blank
| LIBRARYNAME         SPlus library passed to                      Opt     Blank
|                     loadspluslibrary.sas
| LIBRARYLOCATION     SPlus library path passed to                 Opt     Blank
|                     loadspluslibrary.sas
| LOADFIRST           Specifies if top of SPlus library search     Opt     Blank
|                     first passed to loadspluslibrary.sas
|
| Output: None
|
| Global macro variables created: G_GRAPHFILENAME
|
|
| Macros called :
|  (@)tr_putlocals
|  (@)tu_putglobals
|  (@)tu_header
|  (@)tu_footer
|  (@)tu_valparms
|
| **************************************************************************
| Change Log :
|
| Modified By : Ian Barretto            
| Date of Modification : 08Mar07  
| New Version Number :  1 build 2     
| Modification ID :         
| Reason For Modification : Add call to SOURCESCODE.SAS and LOADSPLUSLIBRARY.SAS
|
| Modified By : Ian Barretto            
| Date of Modification : 19Mar07  
| New Version Number :  1 build 3
| Modification ID :         
| Reason For Modification : Remove calls to SOURCESCODE.SAS and LOADSPLUSLIBRARY.SAS
|                           as functionality not working in S-Plus macros 
|
| Modified By : Ian Barretto            
| Date of Modification : 23Mar07  
| New Version Number :  1 build 4
| Modification ID :         
| Reason For Modification : Include MAKESPATH.SAS directly so that able to call
|                           SOURCESCODE.SAS and LOADSPLUSLIBRARY.SAS.
|                           Remove checking of USEODS and ODSFILEFORMAT  
|
| Modified By : Shan Lee            
| Date of Modification : 11Apr07  
| New Version Number :  1 build 5
| Modification ID :         SL001
| Reason For Modification : The code had been assigning graphfilepath as the 
|                           section of g_outfile from the first character to
|                           two characters before the first occurrence of any
|                           text string equivalent to the actual output filename.
|                           This caused a problem when text equivalent to the 
|                           filename also appeared within the directory name:
|                           i.e. the value of graphfilepath would be truncated.
|
| Modified By : Shan Lee            
| Date of Modification : 19Jun08  
| New Version Number :  2 build 1
| Modification ID :         SL002
| Reason For Modification : HRT0201 - apply macro quoting to titles and 
|                                     footnotes when calling the %splusenv
|                                     macro, in order to prevent problems from
|                                     occurring when special characters are
|                                     included in the text of titles or
|                                     footnotes. 
|+----------------------------------------------------------------------------*/

%MACRO tu_splusenv(useODS            = 0,    /* Controls whether to use SASs output delivery system (ODS) */
                   odsFileFormat     = ,     /* ODS File Format */                                                
                   removeSPLUSScript = 0,    /* Specfies whether the S+ script generated in refdata dir is removed following execution*/
                   lineWidth         = 128,  /* Width (in characters) of an output page */                        
                   pageLength        = 64,   /* Length (in lines) of an output page */                            
                   plotWidth         = 11,   /* Plot width in inches */                                           
                   plotHeight        = 8.5,  /* Plot height in inches */                                          
                   plotMarginTop     = 1.25, /* Plot top margin in inches */                                      
                   plotMarginBottom  = 1.25, /* Plot bottom margin in inches */                                   
                   plotMarginLeft    = 1,    /* Plot left margin in inches */                                     
                   plotMarginRight   = 1,    /* Plot right margin in inches */                                    
                   pointSize         = 10,   /* Title and Footnote point size */
                   xAxisLabelSize    = 10,   /* Point size for X axis and tick mark labels */    
                   yAxisLabelSize    = 10,   /* Point size for Y axis and tick mark labels */         
                   zAxisLabelSize    = 10,   /* Point size for Z axis and tick mark labels */ 
                   sourceName        = ,     /* Filename passed to sourcecode.sas */
                   sourceLocation    = ,     /* File location path passed to sourcecode.sas */
                   libraryName       = ,     /* SPlus library passed to loadspluslibrary.sas */
                   libraryLocation   = ,     /* SPlus library path passed to loadspluslibrary.sas */
                   loadFirst         =       /* Specifies if top of SPlus library search first passed to loadspluslibrary.sas */                   
                  );
                            
  %LOCAL MacroVersion MacroName sasdatalibpath l_title1 l_title2 l_title3 l_title4 l_title5 l_title6 l_title7 
         l_title8 l_title9 l_title10 l_foot1 l_foot2 l_foot3 l_foot4 l_foot5 l_foot6 l_foot7
         l_foot8 l_foot9 l_foot10;
         
  %GLOBAL g_graphfilename;
         
  %LET MacroVersion = 2 Build 1;
  %let MacroName = &sysmacroname;
  * Echo values of local and global macro variables to the log ;                                
  %INCLUDE "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_dddata g_textfilesfx g_outfile)
  
  %local pv_abort;
  %let pv_abort=0;                    
  
 /* Remove old graphics output file */
  x rm -f &g_outfile..*;

 /* ----------------------------------------------------------------- */
 /* Parameter Validation */
     
 /* PV1 - removeSPLUSScript: check it's 0 or 1 */
  %if %length(&removeSPLUSScript) = 0 %then
    %do;
      %put %str(RTW)ARNING: &macroname: Macro parameter removeSPLUSScript is not specified. It will be set to 0; 
      %let removeSPLUSScript = 0;
    %end;
  %else  
     %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = removeSPLUSScript, valuelist = 0 1, abortyn = N);
 
 /* PV2 - All the rest parameters: check they are not <blank> and are NUMERIC */
  %local l_list l_i l_thisvar;
  %let l_list = lineWidth     pageLength       plotWidth      plotHeight 
                plotMarginTop plotMarginBottom plotMarginLeft plotMarginRight
                pointSize     xAxisLabelSize   yAxisLabelSize zAxisLabelSize; 
  %let l_i=1;
  %do %while (%length(%scan(&l_list, &l_i, %str( ))) > 0);
    %let l_thisvar=%scan(&l_list, &l_i, %str( ));
    %if %length(&&&l_thisvar) = 0
    %then
      %do;
        %put %str(RTE)RROR: &macroname: Macro parameter(&l_thisvar) can not be blank; 
        %let pv_abort = 1;          
      %end;
    %else
      %do;
        %if %datatyp(&&&l_thisvar) ne NUMERIC
        %then
          %do;
            %put %str(RTE)RROR: &macroname: Macro parameter(&l_thisvar) value (&&&l_thisvar) is not NUMERIC;
            %let pv_abort = 1;
          %end;
        %else %if &&&l_thisvar le 0 %then
          %do; 
            %put %str(RTE)RROR: &macroname: Macro parameter(&l_thisvar) value (&&&l_thisvar) should be positive; 
            %let pv_abort = 1;
          %end; 
      %end;
    %let l_i=%eval(&l_i+1);
  %end;

    /* PV3a - Check that sourceLocation is not blank if sourceName is populated */
  %if %length(&sourceName) > 0 %then
    %do;
    %if %length(&sourceLocation) = 0 %then
      %do;
      %put %str(RTW)ARNING: &macroname: Macro parameter sourceLocation cannot be blank as sourceName is populated; 
    %end;
  %end;

  /* PV3b - Check that sourceName is not blank if sourceLocation is populated */
  %if %length(&sourceLocation) > 0 %then
    %do;
    %if %length(&sourceName) = 0 %then
      %do;
      %put %str(RTW)ARNING: &macroname: Macro parameter sourceName cannot be blank as sourceLocation is populated; 
    %end;
  %end;
  
  /* PV4a - Check that libraryLocation is not blank if libraryName is populated */
  %if %length(&libraryName) > 0 %then
    %do;
    %if %length(&libraryLocation) = 0 %then
      %do;
      %put %str(RTW)ARNING: &macroname: Macro parameter libraryLocation cannot be blank as libraryName is populated; 
    %end;
  %end;

  /* PV4b - Check that libraryName is not blank if libraryLocation is populated */
  %if %length(&libraryLocation) > 0 %then
    %do;
    %if %length(&libraryName) = 0 %then
      %do;
      %put %str(RTW)ARNING: &macroname: Macro parameter libraryName cannot be blank as libraryLocation is populated; 
    %end;
  %end;

  /* PV4c - Check that loadFirst is not blank if libraryName is populated */
  %if %length(&libraryName) > 0 %then
    %do;
    %if %length(&loadFirst) = 0 %then
      %do;
      %put %str(RTW)ARNING: &macroname: Macro parameter loadFirst cannot be blank as libraryName is populated; 
    %end;
  %end;

 
 /*-----------------------------------------------------------------------*/
 /*- complete parameter validation */
 %if %eval(&g_abort. + &pv_abort.) gt 0 %then 
  %do;
    %put %str(RTE)RROR: &macroname: Macro has failed parameter validation check for reasons stated with %str(RTE)RRORs above;
    %tu_abort(option=force);
  %end;
 /*----------------------------------------------------------------------*/

 /*----------------------------------------------------------------------*/
 /* Normal Processing */
  
  /* Creates a sasdatalibpath macro variable which resolves to the reporting effort redata directory */

  DATA _NULL_;
    refdata=SYMGET('g_dddata');
    refdata=TRANWRD(refdata,'/dddata','/refdata');
    CALL SYMPUT('sasdatalibpath',refdata);
  RUN;
  
  /* Create macro variables from Output Dir and Output file name */

  %let g_graphfilename = %scan(&g_outfile,-1,%str(/)); 

  /* 
  / Ensure that graphfilepath is not truncated by considering all text
  / in g_outfile prior to the last forward slash, which divides the 
  / directory name from the filename. SL001
  /-------------------------------------------------------------------*/

  %local lastSlash;
  %let lastSlash = %length(&g_outfile);

  %do %while ( %index(%str(/\), %qsubstr(&g_outfile, &lastSlash, 1)) eq 0 );  
    %let lastSlash = %eval(&lastSlash - 1);
  %end;

  %let graphfilepath = %substr(&g_outfile, 1, %eval(&lastSlash - 1));
   
  /* Call tu_header and creation of macro variables for titles */

  %tu_header;
  
  DATA title;
    SET sashelp.vtitle(WHERE=(type='T'));
    l_title="l_title"||TRIM(LEFT(_N_));
    CALL SYMPUT(l_title,TRIM(text));
    text="";
  RUN;

  /* Call tu_footer and creation of macro variables for footnotes */
  
  %tu_footer(dsetout=temp);
    
  DATA foot;
    SET sashelp.vtitle(WHERE=(type='F'));
    l_foot="l_foot"||TRIM(LEFT(_N_));
    CALL SYMPUT(l_foot,TRIM(text));
    text="";
  RUN;
  
  
  /* Call to splusenv macro */
  
  %splusenv(splusProjectPath        = &sasdatalibpath,         
            graphFilePath           = &graphfilepath,            
            graphFileFormat         = &g_textfilesfx,      
            useODS                  = &useods,                 
            odsFileFormat           = &odsfileformat,       
            includeSPLUSLogInSASLog = 1,
            removeSPLUSScript       = &removeSPLUSScript,      
            removeSPLUSBatch        = 1,       
            removeSPLUSOutput       = 1,      
            removeSPLUSLog          = 1,         
            dos2Unix                = 0,               
            cleanWorkArea           = 1,          
            lineWidth               = &lineWidth,  
            pageLength              = &pageLength,  
            plotWidth               = &plotWidth,    
            plotHeight              = &plotHeight,   
            plotMarginTop           = &plotMarginTop,   
            plotMarginBottom        = &plotMarginBottom,  
            plotMarginLeft          = &plotMarginLeft,   
            plotMarginRight         = &plotMarginRight,   

            /* 
            / SL002 - apply macro quoting, to avoid problems when there are
            / special characters in titles and footnotes.
            /----------------------------------------------------------------*/

            %DO i=1 %TO %EVAL(&g_header0);
               header&i             = %superq(l_title&i),
            %END;   
            %DO i=1 %TO %EVAL(&g_footer0);
               footer&i             = %superq(l_foot&i),
            %END;   

            pointSize               = &pointSize,        
            xAxisLabelSize          = &xAxisLabelSize,          
            yAxisLabelSize          = &yAxisLabelSize,          
            zAxisLabelSize          = &zAxisLabelSize          
           );
           

   /*  Include MAKEPATH instead of using AUTOCALL as header block in macro causes macro to execute */
   /*  incorrectly */

   /* Creates a macro variable which resolves to the reporting effort code directory */

   DATA _NULL_;
     codedir=SYMGET('g_dddata');
     codedir=TRANWRD(codedir,'/dddata','/code');
     CALL SYMPUT('codepath',codedir);
   RUN;

   %include "%trim(&codepath)/makespath.sas";

   /*  Call to sourcescode macro */   

   %sourcescode(sourceName     = &sourceName ,
                sourceLocation = &sourceLocation 
               );              

   /*  Call to loadspluslibrary macro */
   
   %loadspluslibrary(libraryName     = &libraryName ,
                     libraryLocation = &libraryLocation ,
                     loadFirst       = &loadFirst
                    );              
            
%MEND tu_splusenv;
