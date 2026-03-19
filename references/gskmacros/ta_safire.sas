/*--------------------------------------------------------------------------+
| Macro Name    : ta_safire.sas
|
| Macro Version : 3
|
| SAS version   : SAS v9.1
|
| Created By    : Anup R. Patel
|
| Date          : 18-June-2009
|
| Macro Purpose : Creates XML file with population label for inputted data 
|                 display driver
|
| Macro Design  : Procedure
|
| Input Parameters : None
|
| Output: XML file with population label for inputed data display driver
|
| Global macro variables created:
| g_debug       - Specifies the macro debug level, set to 0
| g_study_desc  - Specifies the study label, set to null
| g_ls          - Specifies the appropriate line size for text output file, set to 108
| g_popdata     - Specifies the name of the population dataset from the oracle db
| g_pop         - Specifies the name of the population variable from the oracle db
| g_poplbl      - Specifies the population label from the oracle db
| g_subpop      - Specifies additional population subsetting from the oracle db
| g_dsplytyp    - Specifies display type from the oracle db
| g_dsplynum    - Specifies the display number from the oracle db
| g_title1      - Specifies the first title, set to 'DUMMY TITLE'
| g_title2      - Specifies the second title, set to null
| g_title3      - Specifies the third title, set to null
| g_title4      - Specifies the fourth title, set to null
| g_title5      - Specifies the fifth title, set to null
| g_title6      - Specifies the sixth title, set to null
| g_title7      - Specifies the seventh title, set to null
| g_datadate    - Specifies the date of data, set to null
| g_language    - Specifies the language from the oracle db
| g_abort       - Specifies the debug value, set to 0
|
| Macros called :
| (@) tu_putglobals
| (@) tu_localisation
| (@) tu_header
| (@) tu_chkvarsexist
| (@) tu_abort
|
| Example:
|
| %ta_safire;
|
| **************************************************************************
| Change Log :
|
| Modified By :             Anup Patel
| Date of Modification :    01-May-2013
| New Version Number :      v2
| Modification ID :         
| Reason For Modification : LIBNAME for adamadata and sdtmdata added for
|                           for Data Displays created from CDISC datasets
|                                                                 
| Modified By :             Anthony Cooper
| Date of Modification :    20-Mar-2014
| New Version Number :      v3
| Modification ID :         AJC001
| Reason For Modification : Updates for HRT0294
|                           1) Check for SAS comments in parameters extracted
|                              from HARP database.
|                           2) Increase length of driver macro parameter value
|                              from 200 to 400
|                           3) Check if d_popdata and d_language exist when
|                              driver macro parameters are extracted
|                                                                 
+----------------------------------------------------------------------------*/

%MACRO ta_safire(
);


  /*
  / Setup the SASAUTOS search path.
  /----------------------------------------------------------------------------*/
  
  OPTIONS SASAUTOS=("&g_refdata");

  /*
  / Echo macro version number and values of parameters and global macro
  / variables to the log.
  /----------------------------------------------------------------------------*/
  
  %LOCAL MacroVersion;
  %LET MacroVersion=3;
  %INCLUDE "&g_refdata./tr_putlocals.sas";
  
  /*
  / AJC001: Define g_abort and g_debug here so can use utility macros, e.g.
  | tu_chkvarsexist
  /----------------------------------------------------------------------------*/
  
  %GLOBAL g_debug g_abort;         
  
  %LET g_debug=0;
  %LET g_abort=0;

  %tu_putglobals(varsin=g_debug g_abort g_study_id re_id drvr_id ardata_path user password path g_refdata);


  %LOCAL prefix;
  %LET prefix=%substr(&sysmacroname,3);

  /*
  / Setup libnames for:
  /
  / 1) the output XML file
  / 2) oracle db
  / 3) ardata, sdtmdata and adamdata directory
  /----------------------------------------------------------------------------*/
  
  LIBNAME _webout xml 
    %IF %LENGTH(&xml_outfile) GT 0 %THEN "&xml_outfile";
  ;
  
  LIBNAME harp_ro ORACLE USER=&user PASSWORD=&password PATH="&path";

  LIBNAME ardata "&ardata_path" ACCESS=READONLY;

  %LET re_path = %SUBSTR(&ardata_path,1,%INDEX(&ardata_path,/ardata));

  LIBNAME adamdata "&re_path.adamdata" ACCESS=READONLY;

  LIBNAME sdtmdata "&re_path.sdtm" ACCESS=READONLY;

  /*
  / Extract the driver metdata from oracle
  /----------------------------------------------------------------------------*/
  
  PROC SQL;
    CREATE TABLE &prefix._1 AS
    SELECT a.dvr_id,                         
           a.disp_num,                       
           b.name AS disp_type,                 
           c.pop AS r_pop,
           c.popdata AS r_popdata,
           c.language AS r_language                            
      FROM harp_ro.HARP_DVR_DISP   a,           
           harp_ro.HARP_DISP_TYPE  b,           
           harp_ro.HARP_RE         c            
     WHERE a.re_id         = &re_id 
       AND a.dvr_id        = &drvr_id
       AND a.disp_type_id  = b.disp_type_id   
       AND a.re_id         = c.re_id
       AND a.is_active     = 'T'
       AND c.is_active     = 'T';
  QUIT;

  /*
  / Extract the driver ts_setup macro paramters from oracle
  /----------------------------------------------------------------------------*/
                
  PROC SQL;
    CREATE TABLE &prefix._ts_setup_arg AS
    SELECT dvr_id,
           name LENGTH=15,
           value LENGTH=400        /* AJC001: Increased length from 200 to 400 */
    FROM harp_ro.HARP_MACRO_ARG
    WHERE dvr_id = &drvr_id 
      AND macro_id IN (SELECT macro_id 
                         FROM harp_ro.HARP_MACRO 
                         WHERE is_setup='T'
                         )
      AND name IN ('d_language', 'd_popdata', 'd_pop', 'd_poplbl', 'd_subpop');
  QUIT;
  
  PROC TRANSPOSE DATA=&prefix._ts_setup_arg 
                 OUT=&prefix._ts_setup_arg_trans (DROP=_LABEL_ _NAME_);
    BY dvr_id;
    ID name;
    VAR value;
  RUN;


  /*
  / Combine the driver metadata with ts_setup macro parameters
  / AJC001: Check if d_popdata and d_language exist, if not set to missing.
  / These parameters were added in ts_setup v5 so will not exist if the 
  / Reporting Effort is using an earlier version of ts_setup.
  /----------------------------------------------------------------------------*/
  
  PROC SQL;
    CREATE TABLE &prefix._2 AS
    SELECT a.*,
        %IF %LENGTH(%tu_chkvarsexist(&prefix._ts_setup_arg_trans, d_popdata)) eq 0 %THEN
           b.d_popdata,;
        %ELSE
           '' as d_popdata,;
           b.d_pop,
           b.d_poplbl,
           b.d_subpop,
        %IF %LENGTH(%tu_chkvarsexist(&prefix._ts_setup_arg_trans, d_language)) eq 0 %THEN
           b.d_language;
        %ELSE
           '' as d_language;
    FROM &prefix._1 a LEFT JOIN &prefix._ts_setup_arg_trans b
    ON a.dvr_id = b.dvr_id;
  QUIT;
  
    
  /*
  / Create global macro variables required for tu_header.
  /----------------------------------------------------------------------------*/
    
  %GLOBAL g_study_desc g_ls g_popdata g_pop g_poplbl g_subpop g_dsplytyp g_dsplynum 
          g_title1 g_title2 g_title3 g_title4 g_title5 g_title6 g_title7 g_datadate g_language;
  
  %LET g_study_desc=;
  %LET g_ls=108;
  %LET g_datadate=;
  %LET g_title1=DUMMY TITLE;

  DATA _NULL_;       
    ATTRIB g_popdata LENGTH=$50;    
    ATTRIB g_pop LENGTH=$50;
    ATTRIB g_language LENGTH=$50;         
    SET &prefix._2;      

    /*
    / AJC001: Remove SAS comments if they exist in the parameters
    /--------------------------------------------------------------------------*/
                
    %MACRO remove_comments(varname=);
    
      comment_start=INDEX(&varname,"/*");
    
      DO WHILE(comment_start > 0);

        comment_end=INDEX(&varname,"*/");
        IF comment_end=0 THEN comment_end=LENGTH(&varname);
        IF comment_start=1 THEN string=SUBSTR(&varname,comment_end+2);
        ELSE &varname=SUBSTR(&varname,1,comment_start-1)||SUBSTR(&varname,comment_end+2);
        comment_start=INDEX(&varname,"/*");

      END;
    
    %MEND remove_comments;
    
    %remove_comments(varname=r_pop);
    %remove_comments(varname=d_pop);
    %remove_comments(varname=r_popdata);
    %remove_comments(varname=d_popdata);
    %remove_comments(varname=r_language);
    %remove_comments(varname=d_language);
    %remove_comments(varname=d_poplbl);
    %remove_comments(varname=d_subpop);
    
    g_pop=r_pop;
    IF d_pop NE '' THEN g_pop=d_pop;
    g_popdata=r_popdata;
    IF d_popdata NE '' THEN g_popdata=d_popdata;
    g_language=r_language;
    IF d_language NE '' THEN g_language=d_language;
    
    IF g_popdata NE '' THEN CALL SYMPUT('g_popdata',TRIM(g_popdata));   
    IF g_pop NE '' THEN CALL SYMPUT('g_pop',TRIM(g_pop));           
    IF d_poplbl NE '' THEN CALL SYMPUT('g_poplbl',TRIM(d_poplbl));     
    IF d_subpop NE '' THEN CALL SYMPUT('g_subpop',TRIM(d_subpop));     
    IF disp_type NE '' THEN CALL SYMPUT('g_dsplytyp',TRIM(SUBSTR(disp_type,1,1)));  
    IF disp_num NE '' THEN CALL SYMPUT('g_dsplynum',TRIM(disp_num));
    IF g_language NE '' THEN CALL SYMPUT('g_language',TRIM(g_language));
  RUN; 

  
  %tu_putglobals(varsin=g_study_desc g_ls g_popdata g_pop g_poplbl g_subpop g_dsplytyp g_dsplynum 
                        g_title1 g_title2 g_title3 g_title4 g_title5 g_title6 g_title7 g_datadate g_language);
  
  /*
  / Macro Parameter Validation 
  /--------------------------------------------------------------------------*/
  
    
  /*
  / Check that G_POPDATA exists 
  /--------------------------------------------------------------------------*/
  
  %IF NOT %sysfunc(exist(&g_popdata)) %THEN
  %DO;
    %PUT %str(RTE)RROR: TA_SAFIRE: Dataset &g_popdata does not exist;
    %LET error_message = RTERROR: Dataset &g_popdata does not exist;
    %LET g_abort = 1;   
  %END;
  
  /*
  / If "g_pop" is not blank then:                           
  / Check that the dataset variable represented by "g_pop" is a variable that
  / actually exists in the dataset represented by "g_popdata" - do this by
  / calling %tu_chkvarsexist(&g_pop, &g_popdata).
  /--------------------------------------------------------------------------*/

  %ELSE %IF &G_POP NE %THEN 
  %DO;   
     %IF %NRBQUOTE(%tu_chkvarsexist(&G_POPDATA, &G_POP)) NE %THEN
     %DO;
       %PUT %str(RTE)RROR: TA_SAFIRE: Variable &g_pop does not exist in the dataset &g_popdata;
       %LET error_message = RTERROR: Variable &g_pop does not exist in the dataset &g_popdata;
       %LET g_abort = 1;
     %END;
  %END;

  /*
  / If "g_abort" equals 1 then output error to an xml file and call tu_abort. 
  /--------------------------------------------------------------------------*/
  
  %IF &g_abort EQ 1 %THEN 
  %DO;
    
    DATA _webout.pop_label;
      pop_label="&error_message";
    RUN;
    
    %tu_abort;
    
  %END;
    
  /*
  / Generate population labels from tu_header and output to an xml file 
  /--------------------------------------------------------------------------*/
  
  %tu_localisation; 
                                                            
  %tu_header;
  
  DATA _webout.pop_label (KEEP=pop_label);
    SET sashelp.vtitle(WHERE=(type='T' AND number=2));
    pop_label="("||TRIM(LEFT(TRANWRD(text,"Population: ","")))||" Population)";        
  RUN;                                     
         
%MEND;

%ta_safire;
