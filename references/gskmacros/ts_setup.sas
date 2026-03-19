/****************************************************************************
| Macro Name    : ts_setup.sas
|
| Macro Version : 9 build 1
|
| SAS version   : SAS v9.1
|
| Created By    : Shan Lee
|
| Date          : 16-Jun-2003
|
| Macro Purpose :
|
|  1. Assign all global macro variables that may be referenced by the
|     reporting tools. This includes global macro variables whose values are
|     derived from reporting effort and data display metadata, as well as
|     other global macro variables that are not obtained from the metadata
|     (eg &g_debug).
|
|  2. Assign librefs to enable access to any datasets that may be needed to
|     generate a data display.
|
|  3. Add reporting-effort, study, and compound macro libraries to the macro
|     search path.
|
|  4. Call macros for defining page setup and localisation
|
|  5. Reset any options previously set by %tu_abort.
|
|  6. Validate a sub-set of the global macro variables that were pre-existing
|     and/or created by this macro.
|
|  7. Assign appropriate values for pagesize and linesize options (note that
|     these are the pagesize and linesize of the SAS log - the pagesize and
|     linesize of the actual data displays will be based on the values of
|     global macro variables that are assigned by the page setup macro).
|
|
| Macro Design  : Procedure
|
| Input Parameters :
| 
| Name                Description                                  Opt   Default           
| ---------------------------------------------------------------------------
| D_ANALY_DISP        Specifies whether the data display should    R,    A                 
|                     be fully (re)created, or just the titles     if                      
|                     and footnotes refreshed                      R_US                    
|                     Valid values:                                AGE=                    
|                     * A  Completely re-run the data display     DD                      
|                     * D  Just refresh the titles and footnotes                          
|                     If D is specified, the output will be                                
|                     produced by reusing data stored prior to                             
|                     the output stage of the last run. If the                             
|                     data display has not previously been run, a                          
|                     controlled error will result                                         
|                                                                                          
| D_DATADATE          Specifies the date of the data (used in      O     No default        
|                     header)                                                              
|                     Valid values: date in the text format                                
|                     DDMMMYYYY                                                            
|                     Value will be prefixed with localised                                
|                     version of "Data as of"                                              
|
| D_DEBUG             Specifies debug level. The functionality      R     0        
|                     is defined as follows:                                                              
|
|                     0	 Low level utilities will suppress writing 
|                        of non-essential information to the log 
|                     1	 Low level will output all information to 
|                        the log. 
|                     2	 Switch on SAS mprint and mprintnest* options.
|                     3	 Switch on SAS mlogic and mlogicnest* options.
|                     4	 Switch on SAS symbolgen option.
|                     5	 Temporary datasets and global macro 
|                        variables not deleted. No changes required
|                        to ts_setup.
|                     6	 Sets the SAS option msglevel to I 
|                     9	 Switches on SAS mfile option to output 
|                        generated SAS statements to a file. The file 
|                        will have the name driver_mfile.sas and be 
|                        written to the drivers directory in /arwork
|                     
|                     Debugging levels are additive, e.g. level 3
|                     also contains the functionality of levels 1 
|                     and 2 
|                     * mprintnest and mlogicnest are new options in  
|                     SAS v9.       
|                                                                                          
| D_DSPLANFILE        Specifies pathname of dataset specification  O     No default        
|                     document.                                                            
|                     Valid values: Blank or non-blank text                                
|                     string.                                                              
|                                                                                          
| D_DSPLYNUM          Specifies the display number                 R,    No default        
|                     Valid values: string (not validated)         if                      
|                     (used in the header)                         R_US                    
|                                                                  AGE=                    
|                                                                  DD                      
|                                                                                          
| D_DSPLYTYP          Specifies the display type                   R,    No default        
|                     Valid values:                                if                      
|                     * F (Figure*)                                R_US                    
|                     * L LI LO PP(Listing*)                       AGE=                    
|                     * T TC(Table*)                               DD                      
|                     (used in the header)                                                 
|                     * This value shall be localised                                      
|                                                                                          
| D_FONTSIZE          In general, this parameter is used to        R,    L10               
|                     specify the file extension. However, in      if                      
|                     order to maintain backwards compatibility,   R_US                    
|                     values of "10" or "12" will also be          AGE=                    
|                     acceptable. In these cases, the ts_setup     DD                      
|                     macro will derive the file extension by                              
|                     preceding the "10" or "12" with an "L".                              
|                     Valid values:                                                        
|                     * P08                                                                
|                     * P09                                                                
|                     * P10                                                                
|                     * P11                                                                
|                     * P12                                                                
|                     * L08                                                                
|                     * L09                                                                
|                     * L10                                                                
|                     * L11                                                                
|                     * L12                                                                
|                     * 10                                                                 
|                     * 12                                                                 
|                     The SAS linesize and pagesize options will                           
|                     be automatically set to values that produce                          
|                     a display area of an IDSL-compliant size                             
|                                                                                          
| D_FOOT1             Specifies the first footnote line            O     No default        
|                     Valid values: text string                                            
|                                                                                          
| D_FOOT2             Specifies the second footnote line           O     No default        
|                     Valid values: text string                                            
|                                                                                          
| D_FOOT3             Specifies the third footnote line            O     No default        
|                     Valid values: text string                                            
|                                                                                          
| D_FOOT4             Specifies the fourth footnote line           O     No default        
|                     Valid values: text string                                            
|                                                                                          
| D_FOOT5             Specifies the fifth footnote line            O     No default        
|                     Valid values: text string                                            
|                                                                                          
| D_FOOT6             Specifies the sixth footnote line            O     No default        
|                     Valid values: text string                                            
|                                                                                          
| D_FOOT7             Specifies the seventh footnote line          O     No default        
|                     Valid values: text string                                            
|                                                                                          
| D_FOOT8             Specifies the eighth footnote line           O     No default        
|                     Valid values: text string                                            
|                                                                                          
| D_FOOT9             Specifies the ninth footnote line            O     No default        
|                     Valid values: text string                                            
|                                                                                          
| D_KEEPPOPVARS       Specifies what variables to mergeg into      O     No default        
|                     analysis data set from the population data
|                     set when %tu_getdata gets called
|
| D_LANGUAGE          Specifies the language to be used for the    O     No default        
|                     HARP RT outputs                                                      
|                     Valid values: suffix of the name of an XML                           
|                     file that exists in the HARP RT refdata                              
|                     directory. The file shall be named                                   
|                     TR_LANG_language.XML, e.g.                                           
|                     TR_LANG_BRENG.XML                                                    
|                                                                                          
| D_OUTFILE           Specifies the location and name of the       R,    No default        
|                     output file(s), without the suffix. The      if                      
|                     Reporting Tools will append the appropriate  R_US                    
|                     suffix.                                      AGE=                    
|                                                                  DD                      
|                                                                                          
| D_PGMPTH            Specifies the location and name of the       R,    No default        
|                     program (for use in footer)                  if                      
|                                                                  R_US                    
|                                                                  AGE=                    
|                                                                  DD                      
|                                                                                          
| D_POP               Specifies the name of the population         O     No default 
|                     variable                                                             
|                     Valid values: Name of a variable present in                          
|                     the population dataset                                               
|                                                                                          
| D_POPDATA           Specifies the name of the population         R     No default        
|                     dataset                                                              
|                     Valid values: name of a SAS dataset                                  
|                     containing the variable specified by the                             
|                     d_pop parameter                                                      
|                                                                                          
| D_POPLBL            Specifies the population label (used in      O     The label of the  
|                     header)                                            d_pop variable    
|                     Valid values: text string                          with the value of 
|                     If d_subpop is not blank, a warning will be        the d_subpop      
|                     issued if d_poplbl is set to either a) the         parameter added   
|                     value of d_pop, or b) the label of the             to the end        
|                     variable specified by d_pop                                          
|                                                                                          
| D_PTRTFMT           Name of numeric format for period treatment  O     No default 
|                     group, derived from the population dataset.                          
|                     Valid values: Valid name for a user-defined                          
|                     numeric format.                                                      
|                                                                                          
| D_RTFYN             Specifies if RTF display output should be    R     N
|                     created with standard display output
|                     Valid Value: Y or N
|        
| D_STATUS            Specifies the status of the data display     O     No default        
|                     (used in header)                                                     
|                     Valid values: text string                                            
|                                                                                          
| D_STYPE             Specifies the study type.                    O     No default        
|                     Valid values:                                                        
|                     * XO (crossover)                                                     
|                     PG (parallel group)                                                  
|                                                                                          
| D_SUBPOP            Specifies additional population subsetting   O     No default        
|                     Valid values: a valid where clause (without                          
|                     "where"). Can only include variables that                            
|                     exist in the population dataset (R_POPDATA)                          
|                                                                                          
| D_SUBSET            Specifies additional subsetting to be        O     No default        
|                     applied                                                              
|                     Valid values: a valid where clause (without                          
|                     "where"). Can only include variables that                            
|                     exist in datasets used by the data display                           
|                     macro (see the documentation for individual                          
|                     macros for details)                                                  
|                                                                                          
| D_TITLE1            Specifies the first title line (below the    R,    No default        
|                     standard IDSL title lines)                   if                      
|                     Valid values: text string                    R_US                    
|                                                                  AGE=                    
|                                                                  DD                      
|                                                                                          
| D_TITLE2            Specifies the second title line (below the   O     No default        
|                     standard IDSL title lines)                                           
|                     Valid values: text string                                            
|                                                                                          
| D_TITLE3            Specifies the third title line (below the    O     No default        
|                     standard IDSL title lines)                                           
|                     Valid values: text string                                            
|                                                                                          
| D_TITLE4            Specifies the fourth title line (below the   O     No default        
|                     standard IDSL title lines)                                           
|                     Valid values: text string                                            
|                                                                                          
| D_TITLE5            Specifies the fifth title line (below the    O     No default        
|                     standard IDSL title lines)                                           
|                     Valid values: text string                                            
|                                                                                          
| D_TITLE6            Specifies the sixth title line (below the    O     No default        
|                     standard IDSL title lines)                                           
|                     Valid values: text string                                            
|                                                                                          
| D_TITLE7            Specifies the seventh title line (below the  O     No default        
|                     standard IDSL title lines)                                           
|                     Valid values: text string                                            
|                                                                                          
| D_TRT_INPER         Specifies if (A)(P)TRTCD and  A)(P)TPTRTGRP  O     No default        
|                     are used as &G_TRTCD and  &G_TRTGRP for XO                           
|                     study                                                                
|                     Valid Values: Blank, Y or N                                          
|     
| D_TRTDATA           Specifies treatment data set for display.    O     No default
|                     Valid values: Blank or a existing SAS data 
|                     set. 
|                     Note: It will not be validated in %ts_setup
|                                                                                     
| D_TRTFMT            Name of numeric format for treatment group,  O     No default 
|                     derived from the population dataset.                                 
|                     Valid values: Valid name for a user-defined                          
|                     numeric format.                                                      
|                                                                                          
| D_TRTVAR            Specifies the type of treatment variable(s)  O     No default        
|                     that will be used for this data display,                             
|                     overriding the type specified for the                                
|                     reporting effort (r_trtvar).                                         
|                     Valid values:                                                        
|                     * A (Actual)                                                         
|                     * R (Randomised)                                                     
|                     For A, the following variables will be                               
|                     used: ATRTCD, ATRTGRP, PATRTCD, PATRTGRP,                            
|                     TPATRTCD, TPATRTGP                                                   
|                     For R, the following variables will be                               
|                     used: TRTCD, TRTGRP, PTRTCD, PTRTGRP,                                
|                     TPTRTCD, TPTRTGRP                                                    
|                                                                                          
| D_USERID            Holds the user name of the actual person     R,    %upcase(&sysuserid
|                     generating the data display. It is intended  if    )                 
|                     that the HARP Application will populate      R_US                    
|                     this parameter when it generates a driver    AGE=                    
|                     program. When the user name needs to be      DD                      
|                     shown in footnotes, it is preferable to use                          
|                     this, rather than the UNIX user name, which                          
|                     will always be "HARP" when a data display                            
|                     is generated via the application.                                    
|                     The D_USERID parameter will have a default                           
|                     value derived from the UNIX user name,                               
|                     which can be used to populate footnotes                              
|                     when driver programs are created and run by                          
|                     users at the UNIX command line.                                      
|                     Valid values: Non-blank text string.                                 
|                                                                                          
| R_ARDATA            Specifies the directory path of the A&R      R     No default        
|                     data                                                                 
|                     Valid values: non-blank text string.                                 
|                                                                                          
| R_CENTID            Specifies the variable containing the        R     CENTREID          
|                     centre ID                                                            
|                     Valid values: single variable name                                   
|                     Note for documentation: To be IDSL                                   
|                     compliant, this variable should named INVID                          
|                     (MEDTRACK) or CENTREID                                               
|                                                                                          
| R_CFMTDIR           Specifies the name of a directory            O     No default        
|                     containing a compound level formats catalog                          
|                     Valid values: blank or text string.                                  
|                                                                                          
| R_CLBLFILE          Specifies the location of the compound's     O     No default        
|                     labels file (XML)                                                    
|                                                                                          
| R_DATADATE          Specifies the date of the data (used in      O     No default        
|                     header)                                                              
|                     Valid values: date in the text format                                
|                     DDMMMYYYY                                                            
|                     Value will be prefixed with localised                                
|                     version of "Data as of"                                              
|                                                                                          
| R_DDDATA            Specifies the directory path of the data     R,    No default        
|                     display data, i.e. the datasets that         if                      
|                     underlie the presentation phase of the data  R_US                    
|                     display macros                               AGE=                    
|                     Valid values: non-blank text string.         DD                      
|                                                                                          
| R_DICTION           Specifies the directory path of the GSKDRUG  O     /local/apps/dictio
|                     and MEDDRA dictionary data and format.             naries            
|                     Libname DICTION will be assigned to this                             
|                     path                                                                 
|                     Valid values: blank or non-blank text                                
|                     string.                                                              
|                                                                                          
| R_DMDATA            Specifies the directory path of the DM       R,    No default        
|                     data.                                        if                      
|                     Valid values: non-blank text string, when    R_US                    
|                     required.                                    AGE=                    
|                                                                  AR                      
|                                                                                          
| R_GFMTDIR           Specifies the directory path of global       O     /local/apps/dictio
|                     format.                                            naries            
|                     Valid values: blank or non-blank text                                
|                     string.                                                              
|                                                                                          
| R_INDIC             Specifies the indication                     O     No default        
|                     Not used by HARP RT, but provided for                                
|                     optional use by Developers                                           
|
| R_KEEPPOPVARS       Specifies what variables to mergeg into      O     No default        
|                     analysis data set from the population data
|                     set when %tu_getdata gets called
|                                                                                          
| R_LANGUAGE          Specifies the language to be used for the    R,    BRENG             
|                     HARP RT outputs                              if                      
|                     Valid values: suffix of the name of an XML   R_US                    
|                     file that exists in the HARP RT refdata      AGE=                    
|                     directory. The file shall be named           DD                      
|                     TR_LANG_language.XML, e.g.                                           
|                     TR_LANG_BRENG.XML                                                    
|                                                                                          
| R_MACDIRS           Specifies one or more directories that       O     No default        
|                     contain macros that are to be used by SAS                            
|                     Valid values: Blank, or list of directory                            
|                     names. Each must be quoted (single or                                
|                     double), and each must be separated by a                             
|                     space                                                                
|                     These directories will be added to the                               
|                     "front" of the search path so that SAS will                          
|                     search them first. The left-most directory                           
|                     in the r_macdirs parameter will be the very                          
|                     first to be searched                                                 
|                     Use dot (".") to indicate the directory                              
|                     from which the SAS session was started                               
|                                                                                          
| R_PKDATA            Specifies the directory path of the PK       O     No default        
|                     data.                                                                
|                     Valid values: blank or non-blank text                                
|                     string.                                                              
|                                                                                          
| R_POP               Specifies the name of the population         R     PNITTCD           
|                     variable                                                             
|                     Valid values: Name of a variable present in                          
|                     the population dataset                                               
|                                                                                          
| R_POPDATA           Specifies the name of the population         R     ardata.pop        
|                     dataset                                                              
|                     Valid values: name of a SAS dataset                                  
|                     containing the variable specified by the                             
|                     d_pop parameter                                                      
|                                                                                          
| R_PTRTFMT           Name of numeric format for period treatment  O     rt_ptrf.          
|                     group, derived from the population dataset.                          
|                     Valid values: Valid name for a user-defined                          
|                     numeric format.                                                      
|                                                                                          
| R_RAWDATA           Specifies the directory path of the raw      R,    No default        
|                     data.                                        if                      
|                     Valid values: non-blank text string, when    R_US                    
|                     required.                                    AGE=                    
|                                                                  AR                      
|                                                                                          
| R_REFDATA           Specifies the directory path of the          R     No default        
|                     reference data                                                       
|                     Valid values: non-blank text string.                                 
|                                                                                          
| R_RFMTDIR           Specifies the name of a directory            O     No default        
|                     containing a reporting effort level formats                          
|                     catalog                                                              
|                     Valid values: blank or text string.                                  
|                                                                                          
| R_RLBLFILE          Specifies the location of the reporting      O     No default        
|                     effort's labels file (XML)                                           
|                                                                                          
| R_SFMTDIR           Specifies the name of a directory            O     No default        
|                     containing a study level formats catalog                             
|                     Valid values: blank or text string.                                  
|                                                                                          
| R_SLBLFILE          Specifies the location of the study's        O     No default        
|                     labels file (XML)                                                    
|                                                                                          
| R_STUDY_DESC        Specifies the study label (for use in        O     No default        
|                     header). Incorporates compound description                           
|                                                                                          
| R_STUDY_ID          Specifies the study ID (used in header).     R     No default        
|                     Incorporates compound ID.                                            
|                                                                                          
| R_STYPE             Specifies the study type.                    R     No default        
|                     Valid values:                                                        
|                     * XO (crossover)                                                     
|                     PG (parallel group)                                                  
|                                                                                          
| R_SUBJID            Specifies the variable containing the        R     SUBJID            
|                     subject ID                                                           
|                     Valid values: single variable name                                   
|                     Note for documentation: To be IDSL                                   
|                     compliant, this variable should named                                
|                     SUBJID or USUBJID                                                    
|                                                                                          
| R_TRTDATA           Specifies treatment data set for display.    O     ardata.trt
|                     Valid values: Blank or a existing SAS data 
|                     set. 
|                     Note: It will not be validated in %ts_setup
|                                                                                     
| R_TRT_INPER         Specifies if (A)(P)TRTCD and (A)(P)TPTRTGRP  R     N                 
|                     are used as &G_TRTCD and  &G_TRTGRP for XO                           
|                     study                                                                
|                     Valid Values: Y or N                                                 
|                                                                                          
| R_TRTFMT            Name of numeric format for treatment group,  O     rt_trtf.          
|                     derived from the population dataset.                                 
|                     Valid values: Valid name for a user-defined                          
|                     numeric format.                                                      
|                                                                                          
| R_TRTVAR            Specifies the default type of treatment      R     No default        
|                     variable(s)                                                          
|                     Valid values:                                                        
|                     * A (Actual)                                                         
|                     * R (Randomised)                                                     
|                     For A, the following variables will be                               
|                     used: ATRTCD, ATRTGRP, PATRTCD, PATRTGRP,                            
|                     TPATRTCD, TPATRTGP                                                   
|                     For R, the following variables will be                               
|                     used: TRTCD, TRTGRP, PTRTCD, PTRTGRP,                                
|                     TPTRTCD, TPTRTGRP                                                    
|                                                                                          
| R_USAGE             Flag to indicate whether setup macro is      R     DD                
|                     being called from a data display driver or                           
|                     an AR dataset driver.                                                
|                     Valid values: DD, AR, SDTM or ADAM.        
|                             
| R_DATATYPE          Flag to indicate whether setup macro is      R     IDSL                
|                     processed for IDSL data or CDISC data.                                                
|                     Valid values: IDSL or CDISC.   
| R_ADAMDATA          Specifies the directory path of the ADAM     R,    No default        
|                     data.                                        if                      
|                     Valid values: non-blank text string, when    R_US                    
|                     required.                                    AGE=                    
|                                                                  ADAM                                          
|-----------------------------------------------------------------------------------------
| Output:
|
|  No datasets are created by this macro.
|
|  In general, %ts_setup generates one global macro variable for each of its
|  parameters; and the name of each global macro variable is the same as the
|  name of the corresponding parameter, except that the "r_" or "d_" is
|  replaced by "g_". So, for example, a global macro variables called
|  "g_analy_disp" is created, corresponding to the parameter "d_analy_disp".
|  If the value of the parameter is not missing, then this will be the value
|  of the corresponding global macro variable. However, if the parameter
|  value is missing, then %ts_setup will still declare the corresponding
|  global macro variable in a %global statement, but it will not set the
|  value of the global macro variable to missing.
|
|  The only exception to the above behaviour is for pairs of parameters that
|  correspond to equivalent metadata at the data display and reporting
|  effort levels. These are pairs of parameters whose names are identical,
|  except that one has the "d_" prefix, whilst the other has the
|  "r_prefix". For example, the "r_trtvar" parameter indicates whether
|  randomised or actual treatment variables should be used by default for
|  the given reporting effort; whereas the "d_trtvar" parameter may be
|  used to override this default action, indicating if randomised or actual
|  treatment variables should be used for a given data display regardless
|  of the default for the reporting effort. Whenever such a pair of
|  parameters exists, only one global macro variable is created for that
|  pair. If a non-missing value is specified for the "d_" parameter, then
|  the global macro variable will take the value of this ("d_") parameter.
|  If the "d_" parameter is missing, then the global macro variable will
|  take the value of the "r_" parameter. For example, if &r_trtvar = R and
|  &d_trtvar = A, then the global macro variable "g_trtvar" will be assigned
|  the value "A". However, if &trtvar = R and &d_trtvar = , then the global
|  macro variable "g_trtvar" will be assigned the value "R".
|
|  In release 1.0 of the HARP reporting tools, the only "pair" of parameters,
|  as defined in the above paragraph, is &d_trtvar and &r_trtvar.
|  Therefore, every other parameter of %ts_setup corresponds to exactly one
|  global macro variable. In addition to these global macro variables,
|  %ts_setup creates other global macro variables, described under the
|  section "Global macro variables created".
|
|  %ts_setup assigns the following librefs:
|
|   ardata: Libref for analysis and reporting datasets.
|   dddata: Libref for data display dataset.
|   dmdata: Libref for data management datasets.
|   rawdata: Libref for raw datasets.
|
|  %ts_setup modifies the macro search path such that any directories
|  specified via the global macro variable "g_macdirs" are searched prior to
|  the director(y/ies) that were already specified in the macro search path
|  prior to %ts_setup being called.
|
| Global macro variables created:
|  G_ABORT
|  G_ANALY_DISP
|  G_ARDATA
|  G_CENTID
|  G_CFMTDIR
|  G_CLBLFILE
|  G_DATADATE
|  G_DDDATA
|  G_DDDATASETNAME
|  G_DDDATASETNAMECI
|  G_DEBUG
|  G_DICTION
|  G_DMDATA
|  G_DSPLANFILE
|  G_DSPLYNUM
|  G_DSPLYTYP
|  G_FNC
|  G_FONTSIZE
|  G_FOOT19
|  G_GFMTDIR
|  G_INDIC
|  G_KEEPPOPVARS
|  G_LANGUAGE
|  G_LS
|  G_MACDIRS
|  G_OUTFILE
|  G_PGMPTH
|  G_PKDATA
|  G_POP
|  G_POPDATA
|  G_TRTDATA
|  G_POPLBL
|  G_PS
|  G_PTRTCD
|  G_PTRTFMT
|  G_PTRTGRP
|  G_RAWDATA
|  G_REFDATA
|  G_RFMTDIR
|  G_RLBLFILE
|  G_RTFYN
|  G_SFMTDIR
|  G_SLBLFILE
|  G_STATUS
|  G_STUDY_DESC
|  G_STUDY_ID
|  G_STYPE
|  G_SUBJID
|  G_SUBPOP
|  G_SUBSET
|  G_TEXTFILESFX
|  G_TITLE1-7
|  G_TPTRTCD
|  G_TPTRTGRP
|  G_TRTCD
|  G_TRTSEQCD
|  G_TRTFMT
|  G_TRTSEQFMT
|  G_TRTGRP
|  G_TRTSEQGRP
|  G_TRTVAR
|  G_USAGE
|  G_USERID
|  G_RTF_OUTFILE
|  G_DATATYPE
|
| Macros called :
|  (@)tr_putlocals
|  (@)tu_abort
|  (@)tu_chknames
|  (@)tu_chkvarsexist
|  (@)tu_getdata
|  (@)tu_localisation
|  (@)tu_pagesetup
|  (@)tu_putglobals
|  (@)tu_tidyup
|  (@)tu_words
|
| Example:
| %ts_setup(R_USAGE=DD,
|           R_STYPE=PG,
|           R_SUBJID=SUBJID,
|           R_CENTID=CENTREID,
|           R_TRTVAR=R,
|           R_STUDY_ID=emd20003,
|           R_STUDY_DESC=interim look,
|           R_INDIC=,
|           R_ARDATA=/arenv/arwork/harptestcpd1/emd20003/datalook/ardata,
|           R_DDDATA=/arenv/arwork/harptestcpd1/emd20003/datalook/dddata,
|           R_RAWDATA=/arenv/arwork/harptestcpd1/emd20003/datalook/rawdata,
|           R_DMDATA=/arenv/arwork/harptestcpd1/emd20003/datalook/dmdata,
|           R_REFDATA=/arenv/arwork/harptestcpd1/emd20003/datalook/refdata,
|           R_MACDIRS=".",
|           R_POPDATA=ardata.pop,
|           R_POPDATA=,
|           R_RLBLFILE=,
|           R_SLBLFILE=,
|           R_CLBLFILE=,
|           R_LANGUAGE=BRENG,
|           D_PGMPTH=/arenv/arwork/harptestcpd1/emd20003/datalook/code/ae1.sas,
|           D_DSPLYTYP=T,
|           D_DSPLYNUM=1,
|           D_OUTFILE=/arenv/arwork/harptestcpd1/emd20003/datalook/output/ae1,
|           D_POP=ITT,
|           D_POPLBL=Intention-to-Treat Population,
|           D_SUBPOP=,
|           D_SUBSET=,
|           D_ANALY_DISP=A,
|           D_TITLE1=Summary of All Adverse Events,
|           D_TITLE2=,
|           D_TITLE3=,
|           D_TITLE4=,
|           D_TITLE5=,
|           D_TITLE6=,
|           D_TITLE7=,
|           D_FOOT1=,
|           D_FOOT2=,
|           D_FOOT3=,
|           D_FOOT4=,
|           D_FOOT5=,
|           D_FOOT6=,
|           D_FOOT7=,
|           D_FOOT8=,
|           D_FOOT9=,
|           D_TRTVAR=A,
|           D_STATUS=DRAFT,
|           D_DATADATE=18JUN2003,
|           D_FONTSIZE=12,
|           D_TRTFMT=mytrtfmt.,
|           R_ADAMDATA=,
|           R_DATATYPE=IDSL
|          )
|
|
| **************************************************************************
| Change Log :
|
| Modified By :             Shan Lee
| Date of Modification :    01 Aug 2003
| New Version Number :      1/2
| Modification ID :         SL001
| Reason For Modification : Ensure that if a global macro variable already
|                           exists prior to ts_setup being called (this can
|                           only happen in the "work" area), then a macro
|                           quoting function will be applied to prevent errors
|                           later in the code - this was detected during the
|                           first iteration of unit testing.
| **************************************************************************
| Modified By :             Shan Lee
| Date of Modification :    02 Sep 2003
| New Version Number :      1/3
| Modification ID :         SL002
| Reason For Modification : Set the option missing = ' '.
| **************************************************************************
| Modified By :             Shan Lee
| Date of Modification :    08 Oct 2003
| New Version Number :      1/4
| Modification ID :         SL003
| Reason For Modification : Create a new parameter, D_USERID, to hold the user
|                           name of the actual person generating the data
|                           display. It is intended that the HARP Application
|                           will populate this parameter when it generates a
|                           driver program. When the user name needs to be
|                           shown in footnotes, it is preferable to use this,
|                           rather than the UNIX user name, which will always
|                           be "HARP" when a data display is generated via the
|                           application.
|                           The D_USERID parameter will have a default value
|                           derived from the UNIX user name, which can be
|                           used to populate footnotes when driver programs
|                           are created and run by users at the UNIX command
|                           line.
|
|                           Generate warning messages if the length of a user
|                           specified title or footnote exceeds the linesize.
| **************************************************************************
| Modified By :             Shan Lee
| Date of Modification :    09 Oct 2003
| New Version Number :      1/5
| Modification ID :         SL004
| Reason For Modification : Correct the syntax errors in code that checks
|                           lengths of title and footnote statements.
|                           If titles and footnotes exceed linesize, then the
|                           (RTW)ARNING messages will still be generated, but
|                           the macro will no longer abort.
| **************************************************************************
| Modified By :             Shan Lee
| Date of Modification :    19 Feb 2004
| New Version Number :      2/1
| Modification ID :         SL005
| Reason For Modification : Incorporate amendments specified on change
|                           control form HRT0003 - ie define format search
|                           path.
| **************************************************************************
| Modified By :             Shan Lee
| Date of Modification :    06 Apr 2004
| New Version Number :      2/2
| Modification ID :         SL006
| Reason For Modification : Incorporate amendments specified on change
|                           control form HRT0010 - ie assign
|                           librefs rfmtdir, sfmtdir, and cfmtdir even
|                           when g_rfmtdir, g_sfmtdir, and g_cfmtdir are
|                           blank, and only include a libref in the format
|                           search path if it points to a catalog called
|                           FORMATS. Note that these amendments
|                           replace previous code with a modification ID
|                           of SL005.
|                           Change the default value of d_fontsize
|                           to L10.
|                           Remove calls to tu_abort with the FORCE option,
|                           and only call tu_abort when g_abort = 1.
| **************************************************************************
| Modified By :             Shan Lee
| Date of Modification :    14 Apr 2004
| New Version Number :      2/3
| Modification ID :         SL007
| Reason For Modification : Prior to this modification, g_outfile was used
|                           in the derivation of directory paths that are
|                           included in the format search path. This
|                           modification involves changing the derivation to
|                           use g_ardata instead of g_outfile, because
|                           g_outfile is blank when ts_setup is
|                           invoked from an AR dataset creation program, but
|                           g_ardata should always be non-blank - therefore it
|                           will be possible to assign the format search path
|                           for both AR dataset and data display creation
|                           programs.
| **************************************************************************
| Modified By :             Shan Lee
| Date of Modification :    26 Aug 2004
| New Version Number :      2/4
| Modification ID :         SL008
| Reason For Modification : Create a default format for the treatment groups,
|                           derived from the population dataset. Users will be
|                           able to specify the name of this default format
|                           via a new parameter called D_TRTFMT. The default
|                           value for D_TRTFMT will be trtfmt..
|                           Check value of g_abort and include call to
|                           tu_abort (if g_abort = 1) after main section of
|                           parameter validation has been executed. Note that
|                           this check (and possible call to tu_abort) is
|                           repeated at the end of the macro, because there is
|                           some more parameter validation that can only be
|                           executed within the normal processing section.
|                           Include a call to tu_tidyup at the end, to remove
|                           a temporary dataset that is created if a
|                           treatment format is requested.
| **************************************************************************
| Modified By :             Shan Lee
| Date of Modification :    09 Sep 2004
| New Version Number :      2/5
| Modification ID :         Not applicable: do not want to include modification
|                           ID as a comment in the macro declaration statement.
| Reason For Modification : Change the default name of the treatment format to
|                           rt_trtf..
| **************************************************************************
| Modified By :             Shan Lee
| Date of Modification :    10 Sep 2004
| New Version Number :      2/6
| Modification ID :         SL009
| Reason For Modification : Amend parameter validation for the D_TRTFMT 
|                           parameter so that format names may include
|                           underscores. 
| **************************************************************************
| Modified By :             Shan Lee
| Date of Modification :    27 Oct 2004
| New Version Number :      3/1
| Modification ID :         SL010
| Reason For Modification : Incorporate the amendments requested in change
|                           control form HRT053 (corresponding to version 4
|                           of the unit specification document):
| 
|                         - Include new parameters, R_PKDATA and D_DSPLANFILE.
|                         - Create global macro variables for the new 
|                           parameters.
|                         - If G_USAGE = AR, then global macro variables that
|                           correspond to D_OUTFILE and D_DSPLANFILE will be
|                           created in addition to the global macro variables
|                           that correspond to the R_ parameters.
|                         - If G_USAGE = AR, then values will be assigned to
|                           D_OUTFILE and D_DSPLANFILE, as well as the global
|                           macro variables that correspond to R_ parameters. 
|                         - A global macro variable G_FNC will be created,
|                           regardless of whether G_USAGE is DD or AR. The
|                           value assigned to G_FNC will be the filename
|                           (without suffix) that is at the end of the
|                           pathname given in G_OUTFILE.
|
|                           If an error has been detected, then call tu_abort
|                           immediately after the parameter validation of G_USAGE,
|                           so that the program will terminate without SAS 
|                           warning messages. 
|                         
|                           G_OUTFILE is required when G_USAGE = DD. Prior to
|                           this build of the macro, there was no specific 
|                           check for G_OUTFILE within ts_setup because it was
|                           understood that tu_pagenum was the only macro that 
|                           referenced G_OUTFILE and this macro was always called 
|                           when G_USAGE = DD. Furthermore, tu_pagenum checks the
|                           value of G_OUTFILE. In order to make the validation
|                           of G_OUTFILE more robust, a check will be added to
|                           ts_setup to ensure that G_OUTFILE is not blank when
|                           G_USAGE = DD.                            
| **************************************************************************            
| Modified By :             Paul Jarrett
| Date of Modification :    16 DEC 2004
| New Version Number :      4/1
| Modification ID :         PJ001
| Reason For Modification : Only parameter check g_pop in ts_setup if it is 
|                           actually populated.  See HRT0067. 
| **************************************************************************                           
| Modified By :             Yongwei Wang (YW62951)
| Date of Modification :    16 JAN 2005
| New Version Number :      4/2
| Modification ID :         YW001
| Reason For Modification : The G_TRTGRP, G_TRTCD, G_PTRTGRP, and G_PTRTCD global 
|                           macro variables shall be set, regardless of the 
|                           prevailing value of r_usage (currently they are only 
|                           set of r_usage=DD)Set G_TRTCD, G_TRTGRP, G_PTRTCD and 
|                           G_PTRTGRP values. It is requried by change request 
|                           form HRT0069. 
| **************************************************************************                           
| Modified By :             Yongwei Wang (YW62951)
| Date of Modification :    21 FEB 2005
| New Version Number :      4/3
| Modification ID :         YW002
| Reason For Modification : Added parameter R_DICTION. Global G_DICTION will be
|                           assigned to it and libname DICTION will be created 
|                           for it. The libname will be added to format searching
|                           path. It is requried by change request form HRT0070. 
| **************************************************************************
| Modified By :             Yongwei Wang (YW62951)
| Date of Modification :    11 Nov 2005
| New Version Number :      5/1
| Modification ID :         YW003
| Reason For Modification : Required by change request HRT0095
|                           1. Added new parameter R_FMTDIR
|                           2. Added new global macro variable G_GFMTDIR to 
|                              save &R_FMTDIR
|                           3. Added libname GFMTDIR to point to &G_GFMTDIR
|                           4. Added GFMTDIR to format searching path and
|                              removed DICTION from format searching path
|                           5. Added parameter D_PTRTFMT for period treatment
|                              format. Created D_PTRTFMT from &G_PTRTCD and 
|                              &G_PTRTGRP. Called %tu_getdata before creating
|                              format
|                           6. Added global macro variable &G_TPTRTCD and
|                              &G_TPTRTGRP for trt. period treatment
| **************************************************************************
| Modified By :             Yongwei Wang (YW62951)
| Date of Modification :    08 Dec 2005
| New Version Number :      5/2
| Modification ID :         YW004
| Reason For Modification : Removed _tempPop1_, which passed to DSETOUT1 of 
|                           %tu_getdata. It caused errors during UAT.
| **************************************************************************
| Modified By :             Yongwei Wang (YW62951)
| Date of Modification :    15 June 2006
| New Version Number :      5/3
| Modification ID :         YW005
| Reason For Modification : Requested by change request HRT0123 & HRT128 
|                           1. Assigned treatment global macro variable &G_TRTCD and 
|                              &G_TRTGRP to period treatment variables if &G_STYPE equals   
|                              XO, based on &G_TRT_INPER
|                           2. Added new global macro variable G_TRTDATA, G_TRTSEQFMT,  
|                              G_TRTSEQCD and G_TRTSEQGRP
|                           3. Assign &G_TRTCD and &G_TRTGRP to G_TRTSEQCD and G_TRTSEQGRP                              
|                           4. If &G_TRT_INPER equals Y,  G_TRTCD = &G_TPTRTCD,G_TRTGRP= 
|                              &G_TPTRTGRP G_PTRTCD =&G_TPTRTCD, G_PTRTGRP = &G_TPTRTGRP
|                           5. If &G_TRT_INPER equals N, G_TRTCD = &G_PTRTCD, G_TRTGRP= 
|                              &G_PTRTGRP   G_TRTSEQFMT = &G_TRTFMT, G_TRTFMT = &G_PTRTFMT
|                           6. Added new parameter R_DATADATE(=Blank), R_TRTFMT(=rt_trtf.), 
|                              R_PTRTFMT(=rt_ptrf.), R_POP(=PNITTCD), R_TRT_INPER(=N), 
|                              D_TRT_INPER(=Blank), D_POPDATA(=Blank), D_STYPE(=Blank), 
|                              D_LANGUAGE(=Blank), D_TRTDATA(=ardata.trt)
|                           7. Sorted parameters by alphabetic order
|                           8. Combined assigning and quoting of global macro variables 
| **************************************************************************
| Modified By :             Yongwei Wang (YW62951)
| Date of Modification :    4 Oct 2006
| New Version Number :      5/4
| Modification ID :         YW006
| Reason For Modification : Based on the suggestion by UAT tester (John Sullivan), 
|                           1. Moved the macro variable defination in step 4&5 in 5/3 
|                              after the format creation.
|                           2. Define &G_TRTSEQFMT=&G_TRTFMT in all circumstance, before
|                              redefine &G_TRTFMT
|                           3. Redefine &G_TRTFMT=&G_PTRTFMT even when &G_TRT_INPER 
|                              equals Y                                             
|                           4. Changed default of D_POP, D_TRTFMT and D_PTRTFMT to blank
|                              requested by Lee Seymour at Oct. 26
| **************************************************************************
| Modified By :             Yongwei Wang (YW62951)
| Date of Modification :    29 Feb 2008
| New Version Number :      6/1
| Modification ID :         YW007
|                           1. Added parameter d_debug and set options based on d_debug 
|                              (HRT0193)
|                           2. Modified 'rm -f' system call to make it work for all platform
|                              (HRT0194)
|                           3. Added new parameter d_rtfyn to define g_rtfyn, r_keeppopvars/
|                              d_keeppopvars to define g_keeppopvars, and r_trtdata to define
|                              reporting level treatment dataset (HRT0195)
|                           4. Removed default of d_trtdata
| **************************************************************************
| Modified By :             Shan Lee (fsl33736)
| Date of Modification :    16 Jun 2008
| New Version Number :      6/2
| Modification ID :         SL011
|                           Change request HRT0204-
|             
|                           1. Create global macro variable g_rtf_outfile, to give the 
|                              pathname (directory plus filename) of the 'RTF' file. If the
|                              'RTF' file does not need to be created, then the value of this
|                              global macro variable will be set to blank.
|                           2. If an 'RTF' file needs to be created, then delete the existing
|                              file, so that if the program does not execute to completion, 
|                              the previous version of the file will not be mistaken for one
|                              that has been generated by the most recent execution of the
|                              program (only relevant when r_usage=DD).
| **************************************************************************
| Modified By :             Shan Lee (fsl33736)
| Date of Modification :    19 Jun 2008
| New Version Number :      6/3
| Modification ID :         SL012
|                           Change request HRT0204- Modify the logic of the code that deletes
|                           the existing RTF file. In the previous build of this macro, any
|                           existing RTF file will only be deleted for a data display table
|                           in /arprod where G_RTFYN has been specified as Y. Now we will
|                           delete any existing RTF file for a table in /arprod, regardless of
|                           G_RTFYN. This ensures that a previous version of the RTF file will
|                           not be mistaken for an RTF file created by the most recent
|                           execution of a driver program. 
| **************************************************************************             
| Modified By :             Lee Seymour (ljs21463)
| Date of Modification :    19 Jul 2010
| New Version Number :      7/1
| Modification ID :         LS013
|                           Added code for new SDTM libname as per change control HRT0259
|                           Added new display level parameters D_SUBJID and D_CENTID
| **************************************************************************
| Modified By :             Gaurav Gupta (gg158110)
| Date of Modification :    27 Sep 2012
| New Version Number :      8/1
| Modification ID :         GG014
|                           Changed the derivation of G_STUDY_ID if first three or four characters
|                           in R_STUDY_ID are "MID" or "MID_".
| **************************************************************************             
| Modified By :             Gaurav Gupta (gg158110)
| Date of Modification :    19 Oct 2012
| New Version Number :      9/1
| Modification ID :         GG015
|                           1) Added parameter R_DATATYPE with default value IDSL and 
|                              validated its value to be IDSL or CDISC.
|                           2) Added parameter R_ADAMDATA and assigned library with Read/Write 
|                              permission when R_DATATYPE is CDISC else Read Only.
|                           3) Validate the value of R_USAGE based on the value of R_DATATYPE.
|                           4) Assign the Treatment variables based on the value of R_DATATYPE.
**********************************************************************************************/

%MACRO ts_setup(
D_ANALY_DISP=A, /* Completely re-run data display (A) or refresh titles/footnotes (D) */
D_CENTID=,  /* Centre ID variable (eg INVID CENTREID) */
D_DATADATE=, /* Date of data (if interim look) */
D_DEBUG=0, /* Level of debug */
D_DSPLANFILE=, /* Pathname of dataset specification document */
D_DSPLYNUM=, /* Display number */
D_DSPLYTYP=, /* Display type - ie L LI LO PP (listing), T TC (table), or F (figure) */
D_FONTSIZE=L10, /* File extension indicating font size & orientation (P08 - P12 or L08 - L12) */
D_FOOT1=, /* First footnote */
D_FOOT2=, /* Second footnote */
D_FOOT3=, /* Third footnote */
D_FOOT4=, /* Fourth footnote */
D_FOOT5=, /* Fifth footnote */
D_FOOT6=, /* Sixth footnote */
D_FOOT7=, /* Seventh footnote */
D_FOOT8=, /* Eighth footnote */
D_FOOT9=, /* Ninth footnote */
D_KEEPPOPVARS=, /* Variables should be merged into analysis dataset from pop dataset in %tu_getdata */
D_LANGUAGE=, /* Code representing language used in data displays */
D_OUTFILE=, /* Location and name (minus suffix) of output file */
D_PGMPTH=, /* Location and name of program */
D_POP=, /* Population variable */
D_POPDATA=, /* Population dataset name */
D_POPLBL=, /* Population label */
D_PTRTFMT=, /* Name of period treatment format derived from population dataset */
D_RTFYN=N, /* If RTF display should be created with standard display */
D_STATUS=, /* Status of data display (eg draft) to show in header */
D_STYPE=, /* Study type (ie crossover or parallel group) */
D_SUBJID=, /*Subject variable (SUBJID or USUBJID)*/
D_SUBPOP=, /* Additional population subsetting */
D_SUBSET=, /* Subsetting applied to patient data in addition to subsetting on patients in specified population */
D_TITLE1=, /* First title below data display number */
D_TITLE2=, /* Second title below data display number */
D_TITLE3=, /* Third title below data display number */
D_TITLE4=, /* Fourth title below data display number */
D_TITLE5=, /* Fifth title below data display number */
D_TITLE6=, /* Sixth title below data display number */
D_TITLE7=, /* Seventh title below data display number */
D_TRT_INPER=, /* If (A)(P)TRTCD and (A)(P)TPTRTGRP are used as &G_TRTCD and &G_TRTGRP for XO study */
D_TRTDATA=, /* Treatment dataset name */
D_TRTFMT=, /* Name of treatment format derived from population dataset */
D_TRTVAR=, /* Type of treatment variables to use - ie actual (A) or randomised (R) */
D_USERID=%upcase(&sysuserid), /* User name to show in footnote */
R_ARDATA=, /* Directory of AR datasets */
R_CENTID=CENTREID, /* Centre ID variable (eg INVID CENTREID) */
R_CFMTDIR=, /* Directory containing formats catalog (compound level) */
R_CLBLFILE=, /* Directory of file storing variable labels (compound level) */
R_DATADATE=, /* Date of data (if interim look) */
R_DDDATA=, /* Directory of data display dataset */
R_DICTION=/local/apps/dictionaries, /* Directory of dictionary datasets */
R_DMDATA=, /* Directory of DM datasets */
R_GFMTDIR=/local/apps/dictionaries, /* Directory of global format */
R_INDIC=, /* Indication of compound (not used by standard reporting tools) */
R_KEEPPOPVARS=, /* Variables should be merged into analysis dataset from pop dataset in %tu_getdata */
R_LANGUAGE=BRENG, /* Code representing language used in data displays */
R_MACDIRS=, /* Directory path(s) of macros to be used in addition to standard RT macros */
R_PKDATA=, /* Directory of PK datasets */
R_POP=PNITTCD, /* Population variable */
R_POPDATA=ardata.pop, /* Population dataset name */
R_PTRTFMT=rt_ptrf., /* Name of period treatment format derived from population dataset */
R_RAWDATA=, /* Directory of raw datasets */
R_REFDATA=, /* Directory of reference data */
R_RFMTDIR=, /* Directory containing formats catalog (reporting effort level) */
R_RLBLFILE=, /* Directory of file storing variable labels (reporting effort level) */
R_SDTMDATA=, /* Directory path for SDTM data*/
R_ADAMDATA=, /* Directory path for ADAM data*/
R_SFMTDIR=, /* Directory containing formats catalog (study level) */
R_SLBLFILE=, /* Directory of file storing variable labels (study level) */
R_STUDY_DESC=, /* Study description */
R_STUDY_ID=, /* Study identifier */
R_STYPE=, /* Study type (ie crossover or parallel group) */
R_SUBJID=SUBJID, /* Subject variable (eg SUBJID USUBJID) */
R_TRTDATA=ardata.trt, /* Treatment dataset name */
R_TRT_INPER=N, /* If (A)(P)TRTCD and (A)(P)TPTRTGRP are used as &G_TRTCD and &G_TRTGRP for XO study */
R_TRTFMT=rt_trtf., /* Name of treatment format derived from population dataset */
R_TRTVAR=, /* Type of treatment variables (ie actual (A) or randomised (R)) */
R_USAGE=DD, /* Flag indicating whether data display or AR dataset driver */
R_DATATYPE=IDSL /* Flag indicating whether code is processed by IDSL data or CDISC data*/
      );

/*
/ Create G_REFDATA - this needs to be done before echoing local macro
/ variables to the log, since G_REFDATA is used to identify the location of
/ tr_putlocals.sas.
/----------------------------------------------------------------------------*/

  %global G_REFDATA;
  %if %nrbquote(&R_REFDATA) ne %then %let G_REFDATA = &R_REFDATA;
  %let G_REFDATA = %nrbquote(&G_REFDATA);

/*
/ Echo macro version number and values of parameters and global macro
/ variables to the log.
/----------------------------------------------------------------------------*/

  %local MacroVersion;
  %let MacroVersion = 9 build 1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals()

/*
/ Declare any local macro variables that need to be created for parameter
/ validation or normal processing.
/----------------------------------------------------------------------------*/

  %local LST_FILE CURR_PATH L_TRTVAR N ISVALID NUM_WORDS;        /* SL003 SL011 */

/*
/ Create G_DATATYPE, G_USAGE and G_ABORT.
/
/ G_USAGE needs to created before other global macro variables are created,
/ because the value of G_USAGE determines which of the other
/ global macro variables need to be created. G_USAGE takes the value of the
/ R_USAGE parameter if it is non-blank.
/
/ G_ABORT needs to be created for the validation of G_USAGE. It will be
/ initialised by calling the TU_ABORT macro.
/----------------------------------------------------------------------------*/

  %global G_DATATYPE G_USAGE G_ABORT G_DEBUG;

  /* Adding G_DATATYPE as per change id gg015. */

  %if %nrbquote(&R_DATATYPE) ne %then %let G_DATATYPE = &R_DATATYPE;
  %let G_DATATYPE = %nrbquote(%upcase(&G_DATATYPE));

  /* End of change id gg015. */

  %if %nrbquote(&R_USAGE) ne %then %let G_USAGE = &R_USAGE;
  %let G_USAGE = %nrbquote(%upcase(&G_USAGE));

  %if %nrbquote(&D_DEBUG) ne %then %let G_DEBUG = %nrbquote(&D_DEBUG);

/*
/ If the global macro variable "g_debug" does not have a value assigned to
/ it, then set it to "0"; otherwise, do not assign a value to it.
/----------------------------------------------------------------------------*/

  %if %nrbquote(&G_DEBUG) eq %then
  %do;
    %let G_DEBUG = 0;
  %end;

/*
/ YW002:
/ R_DICTION should be a required parameter. To make the macro compatible with 
/ previous version, if R_DICTION is blank, set it to /local/apps/dictionaries. 
/----------------------------------------------------------------------------*/

  %if %nrbquote(&r_diction) eq %then
  %do;
    %let r_diction=/local/apps/dictionaries;
    %put %str(RTN)OTE: TS_SETUP: Value of R_DICTION can not be blank. It has been set to /local/apps/dictionaries;
  %end;

/*
/ YW003:
/ R_GFMTDIR should be a required parameter. To make the macro compatible with 
/ previous version, if R_GFMTDIR is blank, set it to /local/apps/dictionaries. 
/----------------------------------------------------------------------------*/

  %if %nrbquote(&r_gfmtdir) eq %then
  %do;
    %let r_gfmtdir=/local/apps/dictionaries;
    %put %str(RTN)OTE: TS_SETUP: Value of R_GFMTDIR can not be blank. It has been set to /local/apps/dictionaries;
  %end;

/*
/ Reset any options previously set by %tu_abort by calling
/ %tu_abort(option=reset)
/----------------------------------------------------------------------------*/

  %tu_abort(option = reset)

/* Validating G_DATATYPE and G_USAGE as per change id gg015. */

/*
/ Check that G_DATATYPE is either IDSL or CDISC.
/----------------------------------------------------------------------------*/

  %if &G_DATATYPE ne IDSL and &G_DATATYPE ne CDISC %then
  %do;
    %put %str(RTE)RROR: TS_SETUP: Datatype (R_DATATYPE) should be equal to either IDSL or CDISC.;
    %let g_abort = 1; 
  %end;

/*
/ Check that G_USAGE is either DD, AR or SDTM when G_DATATYPE is IDSL and 
/ DD, SDTM or ADAM when G_DATATYPE is CDISC.
/----------------------------------------------------------------------------*/

  %if &G_DATATYPE eq IDSL %then
  %do;
    %if &G_USAGE ne DD and &G_USAGE ne AR and &G_USAGE ne SDTM %then
    %do;
      %put %str(RTE)RROR: TS_SETUP: Usage (R_USAGE) should be equal to either DD, AR or SDTM when R_DATATYPE is IDSL.; 	
      %let g_abort = 1;   /* SL006 */
    %end;
  %end;
  %else
  %do;
    %if &G_USAGE ne DD and &G_USAGE ne SDTM and &G_USAGE ne ADAM %then
    %do;
      %put %str(RTE)RROR: TS_SETUP: Usage (R_USAGE) should be equal to either DD, SDTM or ADAM when R_DATATYPE is CDISC.; 	
      %let g_abort = 1;
    %end;
  %end; /* End of change id gg015. */

  %if &G_USAGE eq DD and (( %qupcase(&D_RTFYN) ne Y) and (%qupcase(&D_RTFYN) ne N)) %then
  %do;
    %put %str(RTE)RROR: TS_SETUP: Value of D_RTFYN(=&d_rtfyn) is invalid. Valid value should be Y or N.;
    %let g_abort = 1;  
  %end;

/*
/ Check that if value of &g_debug is valid..
/----------------------------------------------------------------------------*/

  %if %sysfunc(indexw(0 1 2 3 4 5 6 9, %nrbquote(&d_debug))) le 0 %then
  %do;
    %put %str(RTE)RROR: TS_SETUP: Value of D_DEBUG(=&d_debug) is invalid. Valid value should be 0 1 2 3 4 5 6 or 9;
    %let g_abort = 1;        
  %end;  

/*
/ Call %tu_abort if any problems have been detected.
/----------------------------------------------------------------------------*/

  %if &g_abort %then
  %do;
    %tu_abort()
  %end;

/*
/ If G_USAGE is DD, use %global statement to create global macro variables
/ for each of the macro parameters - the name of each global macro variable
/ is equivalent to name of the corresponding macro parameter, except that
/ the "d_" or "r_" is replaced by "g_". For example, the global macro
/ variable "g_stype" needs to be created, corresponding to the macro
/ parameter "r_stype".
/  -> If G_USAGE is AR, do the above only for "R_" parameters, D_OUTFILE
/     and D_DSPLANFILE. 
/
/ If G_USAGE is DD, in the same %global statement, create global macro
/ variables for each of the macro variables specified in section 2.2 [of the
/ unit specification].
/  -> If G_USAGE is AR, only create G_DEBUG and G_FNC.  
/
/ Note that there is no need to declare G_REFDATA as global, since this has
/ already been done prior to echoing macro version number to the log.
/
/ Note that there is no need to declare G_USAGE or G_ABORT as global, since
/ this has already been done previously.
/
/ YW005: All global variables for AR are also for DD. So declared them
/ in one place. Added G_TRTSEQCD G_TRTSEQGRP G_TRTSEQFMT.
/--------------------------------------------------------------------------*/
                                                           
/*
/ If G_USAGE is DD, for each parameter of %ts_setup except &d_trtvar and
/ &r_trtvar, test if the parameter has a non-missing value - if it does, then
/ assign this value to the corresponding global macro variable. If it does
/ not, then do not assign any value to the corresponding macro variable.
/  -> If G_USAGE is AR, do the above only for each "R_" parameter
/     (except R_TRTVAR) and for D_OUTFILE and D_DSPLANFILE.
/
/ No need to assign G_REFDATA, since this was done at the start of the macro
/ prior to echoing the macro version number to the log.
/
/ No need to assign G_USAGE, since this was done previously.
/----------------------------------------------------------------------------*/

/*
/ YW005: combined quoting and assigning of global macro variables together.
/
/ Apply quoting functions to each of the global macro variables that
/ correspond to parameters, so that their resolved values can be treated as
/ text that does not contain any special characters.
/ The purpose of doing this is to avoid problems when the resolved values are
/ used in conditions within %if ... %then statements.
/
/ Note that regardless of whether the global macro variables directly take the
/ values of macro parameters or were assigned prior to calling this
/ macro (only possible if a user is running a driver program from the "work"
/ area), the macro quoting will still be applied to the global macro variable
/ either way.
/
/ Note also that the following code does not apply quoting functions to
/ G_REFDATA and G_USAGE, since quoting functions were applied to these
/ parameters earlier in the code.
/
/ SL011
/
/ Declare global macro variable G_RTF_OUTFILE, which will give the pathname
/ of any 'RTF' file that needs to be created, if G_USAGE=DD.
/----------------------------------------------------------------------------*/

  %global G_STYPE G_SUBJID G_CENTID G_STUDY_ID G_STUDY_DESC G_INDIC G_ARDATA 
          G_DDDATA G_MACDIRS G_POPDATA G_RLBLFILE G_SLBLFILE G_CLBLFILE G_RFMTDIR 
          G_SFMTDIR G_CFMTDIR G_LANGUAGE G_RAWDATA G_SDTMDATA G_ADAMDATA G_DMDATA 
          G_PKDATA G_OUTFILE G_FNC G_DICTION G_GFMTDIR G_DSPLANFILE G_TRTDATA G_KEEPPOPVARS 
          
          /* treatment related global macro variables */          
          G_TRTVAR G_TRTCD G_TRTGRP G_PTRTCD G_PTRTGRP G_TPTRTCD G_TPTRTGRP 
          G_TRTSEQCD G_TRTSEQGRP
        
          G_TRTFMT G_PTRTFMT G_TRTSEQFMT G_TRT_INPER G_DATADATE G_POP
          ;    

  %if %nrbquote(&D_DSPLANFILE) ne %then %let G_DSPLANFILE = %nrbquote(&D_DSPLANFILE);    /* SL010 */
  %if %nrbquote(&D_OUTFILE)    ne %then %let G_OUTFILE    = %nrbquote(&D_OUTFILE);       /* SL010 */
  %if %nrbquote(&R_ARDATA)     ne %then %let G_ARDATA     = %nrbquote(&R_ARDATA);
  %if %nrbquote(&R_SDTMDATA)   ne %then %let G_SDTMDATA   = %nrbquote(&R_SDTMDATA);      /* LS013 */
  %if %nrbquote(&R_ADAMDATA)   ne %then %let G_ADAMDATA   = %nrbquote(&R_ADAMDATA);
  %if %nrbquote(&R_CENTID)     ne %then %let G_CENTID     = %qupcase(&R_CENTID);
  %if %nrbquote(&D_CENTID)     ne %then %let G_CENTID     = %qupcase(&D_CENTID);
  %if %nrbquote(&R_CFMTDIR)    ne %then %let G_CFMTDIR    = %nrbquote(&R_CFMTDIR);
  %if %nrbquote(&R_CLBLFILE)   ne %then %let G_CLBLFILE   = %nrbquote(&R_CLBLFILE);
  %if %nrbquote(&R_DATADATE)   ne %then %let G_DATADATE   = %nrbquote(&R_DATADATE);
  %if %nrbquote(&R_DDDATA)     ne %then %let G_DDDATA     = %nrbquote(&R_DDDATA);
  %if %nrbquote(&R_DICTION)    ne %then %let G_DICTION    = %nrbquote(&R_DICTION);       /* YW002 */
  %if %nrbquote(&R_DMDATA)     ne %then %let G_DMDATA     = %nrbquote(&R_DMDATA);
  %if %nrbquote(&R_GFMTDIR)    ne %then %let G_GFMTDIR    = %nrbquote(&R_GFMTDIR);       /* YW003 */
  %if %nrbquote(&R_INDIC)      ne %then %let G_INDIC      = %nrbquote(&R_INDIC);
  %if %nrbquote(&R_LANGUAGE)   ne %then %let G_LANGUAGE   = %nrbquote(&R_LANGUAGE);
  %if %nrbquote(&R_MACDIRS)    ne %then %let G_MACDIRS    = %nrbquote(&R_MACDIRS);
  %if %nrbquote(&R_PKDATA)     ne %then %let G_PKDATA     = %nrbquote(&R_PKDATA);        /* SL010 */
  %if %nrbquote(&R_POP)        ne %then %let G_POP        = %qupcase(&R_POP);
  %if %nrbquote(&R_POPDATA)    ne %then %let G_POPDATA    = %qupcase(&R_POPDATA);
  %if %nrbquote(&R_PTRTFMT)    ne %then %let G_PTRTFMT    = %nrbquote(&R_PTRTFMT);        
  %if %nrbquote(&R_RAWDATA)    ne %then %let G_RAWDATA    = %nrbquote(&R_RAWDATA);
  %if %nrbquote(&R_RFMTDIR)    ne %then %let G_RFMTDIR    = %nrbquote(&R_RFMTDIR);
  %if %nrbquote(&R_RLBLFILE)   ne %then %let G_RLBLFILE   = %nrbquote(&R_RLBLFILE);
  %if %nrbquote(&R_SFMTDIR)    ne %then %let G_SFMTDIR    = %nrbquote(&R_SFMTDIR);
  %if %nrbquote(&R_SLBLFILE)   ne %then %let G_SLBLFILE   = %nrbquote(&R_SLBLFILE);
  %if %nrbquote(&R_STUDY_DESC) ne %then %let G_STUDY_DESC = %nrbquote(&R_STUDY_DESC);

/* GG014: Changing the derivation of R_STUDY_ID for MID studies. */
  %if %nrbquote(&R_STUDY_ID) ne %then 
  %do;
    %if %upcase(%substr(&R_STUDY_ID,1,3)) eq MID %then
    %do;
      %if %substr(&R_STUDY_ID,4,1) eq _ %then
      %do;
        %let G_STUDY_ID = %nrbquote(%substr(&R_STUDY_ID,5));
      %end;
      %else
      %do;
        %let G_STUDY_ID = %nrbquote(%substr(&R_STUDY_ID,4));
      %end;
    %end;
    %else
    %do;
      %let G_STUDY_ID = %nrbquote(&R_STUDY_ID);
    %end;

    %put %str(RTN)OTE: &sysmacroname: Updated G_STUDY_ID is: "&G_STUDY_ID";
  %end;
/* End of change id GG014 */

  %if %nrbquote(&R_STYPE)      ne %then %let G_STYPE      = %qupcase(&R_STYPE);
  %if %nrbquote(&R_SUBJID)     ne %then %let G_SUBJID     = %qupcase(&R_SUBJID);
  %if %nrbquote(&D_SUBJID)     ne %then %let G_SUBJID     = %qupcase(&D_SUBJID);
  %if %nrbquote(&R_TRT_INPER)  ne %then %let G_TRT_INPER  = %qupcase(&R_TRT_INPER); 
  %if %nrbquote(&R_TRTFMT)     ne %then %let G_TRTFMT     = %nrbquote(&R_TRTFMT);             
  %if %nrbquote(&R_TRTDATA)    ne %then %let G_TRTDATA    = %qupcase(&R_TRTDATA);
  %if %nrbquote(&R_KEEPPOPVARS) ne %then %let G_KEEPPOPVARS= %qupcase(&R_KEEPPOPVARS);
  
  %if &G_USAGE eq DD %then
  %do;

    %global G_TITLE1 G_TITLE2 G_TITLE3 G_TITLE4 G_TITLE5 G_TITLE6 G_TITLE7           
            G_FOOT1 G_FOOT2 G_FOOT3 G_FOOT4 G_FOOT5 G_FOOT6 G_FOOT7 G_FOOT8 G_FOOT9 
            G_PGMPTH G_DSPLYTYP G_DSPLYNUM G_FONTSIZE G_USERID G_LS G_PS
            G_POPLBL G_SUBPOP G_SUBSET G_ANALY_DISP G_RTFYN
            G_STATUS G_DSPLANFILE G_DDDATASETNAME G_DDDATASETNAMECI G_TEXTFILESFX            
            G_RTF_OUTFILE
          ;        
          
    %if %nrbquote(&D_ANALY_DISP) ne %then %let G_ANALY_DISP = %qupcase(&D_ANALY_DISP);
    %if %nrbquote(&D_DATADATE)   ne %then %let G_DATADATE   = %nrbquote(&D_DATADATE);
    %if %nrbquote(&D_DSPLYNUM)   ne %then %let G_DSPLYNUM   = %nrbquote(&D_DSPLYNUM);
    %if %nrbquote(&D_DSPLYTYP)   ne %then %let G_DSPLYTYP   = %qupcase(&D_DSPLYTYP);
    %if %nrbquote(&D_FONTSIZE)   ne %then %let G_FONTSIZE   = %nrbquote(&D_FONTSIZE);
    %if %nrbquote(&D_FOOT1)      ne %then %let G_FOOT1      = %nrbquote(&D_FOOT1);
    %if %nrbquote(&D_FOOT2)      ne %then %let G_FOOT2      = %nrbquote(&D_FOOT2);
    %if %nrbquote(&D_FOOT3)      ne %then %let G_FOOT3      = %nrbquote(&D_FOOT3);
    %if %nrbquote(&D_FOOT4)      ne %then %let G_FOOT4      = %nrbquote(&D_FOOT4);
    %if %nrbquote(&D_FOOT5)      ne %then %let G_FOOT5      = %nrbquote(&D_FOOT5);
    %if %nrbquote(&D_FOOT6)      ne %then %let G_FOOT6      = %nrbquote(&D_FOOT6);
    %if %nrbquote(&D_FOOT7)      ne %then %let G_FOOT7      = %nrbquote(&D_FOOT7);
    %if %nrbquote(&D_FOOT8)      ne %then %let G_FOOT8      = %nrbquote(&D_FOOT8);
    %if %nrbquote(&D_FOOT9)      ne %then %let G_FOOT9      = %nrbquote(&D_FOOT9);
    %if %nrbquote(&D_LANGUAGE)   ne %then %let G_LANGUAGE   = %nrbquote(&D_LANGUAGE);             
    %if %nrbquote(&D_PGMPTH)     ne %then %let G_PGMPTH     = %nrbquote(&D_PGMPTH);
    %if %nrbquote(&D_POP)        ne %then %let G_POP        = %qupcase(&D_POP);
    %if %nrbquote(&D_POPDATA)    ne %then %let G_POPDATA    = %qupcase(&D_POPDATA);
    %if %nrbquote(&D_POPLBL)     ne %then %let G_POPLBL     = %nrbquote(&D_POPLBL);
    %if %nrbquote(&D_PTRTFMT)    ne %then %let G_PTRTFMT    = %nrbquote(&D_PTRTFMT);       /* SL008 */
    %if %nrbquote(&D_STATUS)     ne %then %let G_STATUS     = %nrbquote(&D_STATUS);
    %if %nrbquote(&D_STYPE)      ne %then %let G_STYPE      = %qupcase(&D_STYPE);
    %if %nrbquote(&D_SUBPOP)     ne %then %let G_SUBPOP     = %nrbquote(&D_SUBPOP);
    %if %nrbquote(&D_SUBSET)     ne %then %let G_SUBSET     = %nrbquote(&D_SUBSET);
    %if %nrbquote(&D_TITLE1)     ne %then %let G_TITLE1     = %nrbquote(&D_TITLE1);
    %if %nrbquote(&D_TITLE2)     ne %then %let G_TITLE2     = %nrbquote(&D_TITLE2);
    %if %nrbquote(&D_TITLE3)     ne %then %let G_TITLE3     = %nrbquote(&D_TITLE3);
    %if %nrbquote(&D_TITLE4)     ne %then %let G_TITLE4     = %nrbquote(&D_TITLE4);
    %if %nrbquote(&D_TITLE5)     ne %then %let G_TITLE5     = %nrbquote(&D_TITLE5);
    %if %nrbquote(&D_TITLE6)     ne %then %let G_TITLE6     = %nrbquote(&D_TITLE6);
    %if %nrbquote(&D_TITLE7)     ne %then %let G_TITLE7     = %nrbquote(&D_TITLE7);
    %if %nrbquote(&D_TRT_INPER)  ne %then %let G_TRT_INPER  = %qupcase(&D_TRT_INPER);     /* YW004 */
    %if %nrbquote(&D_TRTFMT)     ne %then %let G_TRTFMT     = %nrbquote(&D_TRTFMT);       /* SL008 */
    %if %nrbquote(&D_USERID)     ne %then %let G_USERID     = %nrbquote(&D_USERID);       /* SL003 */  
    %if %nrbquote(&D_TRTDATA)    ne %then %let G_TRTDATA    = %qupcase(&D_TRTDATA);
    %if %nrbquote(&D_KEEPPOPVARS) ne %then %let G_KEEPPOPVARS= %qupcase(&D_KEEPPOPVARS);
    %if %nrbquote(&D_RTFYN)      ne %then %let G_RTFYN      = %qupcase(&D_RTFYN);
  %end; /* %if &G_USAGE eq DD %then */

  %if %qupcase(&G_KEEPPOPVARS) eq _NONE_ %then %let G_KEEPPOPVARS=%nrbquote();

/*
/ If G_OUTFILE is not blank, then extract the filename (without suffix), which
/ is at the end of the pathname stored in G_OUTFILE, and let this be the value
/ assigned to G_FNC.                   SL010
/----------------------------------------------------------------------------*/

  %if &G_OUTFILE ne %then 
  %do;
    %let G_FNC = %scan(%nrbquote(&G_OUTFILE), -1, /\);
  %end;

/*
/ Based on &g_debug to turn on debug level functionality
/----------------------------------------------------------------------------*/

  %if &g_debug ge 2  %then 
  %do;
    %if %scan(&sysver, 1) ge 9 %then options mprint mprintnest;
    %else options mprint;
  %end;
  %if &g_debug ge 3 %then
  %do;
    %if %scan(&sysver, 1) ge 9 %then mlogic mlogicnest;
    %else mlogic;
  %end;
  %if &g_debug ge 4 %then symbolgen;
  %if &g_debug ge 6 %then msglevel=I;;

  %if &g_debug ge 9 %then
  %do;  
    %let LST_FILE = %sysfunc(getoption(print)); 
   
    %let n=%eval(%length(&LST_FILE) - %length(%scan(%nrbquote(&LST_FILE), -1, /\)));
   
    %if &n gt 0 %then %let LST_FILE=%substr(&LST_FILE, 1, &n);
    %else %let LST_FILE=;
   
    %if %nrbquote(&LST_FILE) ne %then
    %do;
      %let LST_FILE=%sysfunc(tranwrd(&LST_FILE, arprod, arwork));
    %end;
   
    %if %nrbquote(&G_FNC) eq %then
    %do;
      %if %sysfunc(fileexist(%nrbquote(&LST_FILE))) %then
         filename mprint "&LST_FILE.driver_mfile.sas";   
      %else
         filename mprint "driver_mfile.sas";;
      option mfile;
    %end;
    %else %do;
      %if %sysfunc(fileexist(%nrbquote(&LST_FILE))) %then
         filename mprint "&LST_FILE.&G_FNC._mfile.sas";   
      %else
         filename mprint "&G_FNC._mfile.sas";;
         option mfile;
    %end; /* %if %nrbquote(&G_FNC) eq %else */
   
  %end; /* %if &g_debug ge 9 */

/*
/ If G_USAGE is DD, delete the ".lst" file associated with the program name.
/ This file will be located in the session's start-up directory unless it
/ was over-ridden by the use of the -PRINT option on the command line.
/ If the -PRINT option was not used on the command line, the value of the
/ PRINT option by default corresponds to the session's start up directory.
/ Therefore, the value of the PRINT option will always give the directory and
/ name of the ".lst" file that is associated with the program name.
/----------------------------------------------------------------------------*/

  %if &G_USAGE eq DD %then
  %do;

    %let LST_FILE = %sysfunc(getoption(print));

    %if %nrbquote(&LST_FILE) ne %then
    %do;                     
      filename _setup0 "&LST_FILE";
      
      data _null_;
        rc=fdelete('_setup0');
        stop;
      run;
      
      filename _setup0 clear;
    %end;  

  /*
  / SL011
  /
  / If G_USAGE is DD, determine whether or not an 'RTF' file needs to be
  / generated, assign the pathname to G_RTF_OUTFILE or set the global macro
  / variable to blank if no 'RTF' file needs to be generated.
  / 
  / If an 'RTF' file needs to be generated, then delete the existing file,
  / so that if the program fails to execute successfully, the previous version
  / of the file will not be mistaken for one that has been generated by the
  / current execution of the program.
  /
  / SL012
  /
  / Delete any exisitng RTF file for any data display table created in /arprod,
  / regardless of the value of &g_rtfyn. This is to ensure that an RTF file
  / created by a previous execution of the driver will not be mistaken for one
  / created by the most recent execution.
  /--------------------------------------------------------------------------*/


    %if %upcase(&g_dsplytyp) eq T and %scan(&g_outfile, 2, /) eq arprod %then
    %do;

  /*
  / Create a macro variable equivalent to g_outfile, but referring to the
  / 'documents' directory rather than the 'output' directory.
  / Do not simply use %indexw to locate 'output' in g_outfile, because
  / there might be a compound, study or reporting effort that contains the
  / text 'output' in its name.
  /-------------------------------------------------------------------------*/

      %let num_words = %tu_words(&g_outfile, delim = /);

      %do n = 1 %to &num_words;
        %if &n ne &num_words - 1 %then
	    %let g_rtf_outfile = &g_rtf_outfile./%scan(&g_outfile, &n, /);
        %else
	    %let g_rtf_outfile = &g_rtf_outfile./documents;
      %end;

  /*
  / Delete the RTF version of the data display, if it exists.
  /-------------------------------------------------------------------------*/

      filename _setup0 "&g_rtf_outfile..rtf";

      data _null_;
        rc=fdelete('_setup0');
      run;

      filename _setup0 clear;

  /*
  / SL012
  /
  / The final value of G_RTF_OUTFILE should be set to blank if no RTF file
  / has been requested, so that it is possible to see from the value of this
  / global macro variable whether or not an RTF file is required, as well as
  / the pathname of the file if it is required. 
  /-------------------------------------------------------------------------*/

      %if %upcase(&g_rtfyn) ne Y %then %let g_rtf_outfile = ;


    %end; /*  %if %upcase(&g_dsplytyp) eq T and %scan(&g_outfile, 2, /) eq arprod */
    %else %let g_rtf_outfile = ;


  /*
  / If G_USAGE is DD, if in batch execution mode (&SYSENV eq BACK), set option
  / ERRORABEND, else set NOERRORABEND
  /--------------------------------------------------------------------------*/

    %if &SYSENV eq BACK %then
    %do;
      options errorabend;
    %end;
    %else
    %do;
      options noerrorabend;
    %end;

  %end; /* %if &G_USAGE eq DD %then */

/*
/ If &d_trtvar is not missing, set g_trtvar to &d_trtvar .
/ Else if &r_trtvar is not missing, set g_trtvar to &r_trtvar 
/ else don't set g_trtvar
/
/ YW001: Removed "%if &G_USAGE eq DD %then" statement 
/----------------------------------------------------------------------------*/

  %if %nrbquote(&D_TRTVAR) ne %then %let G_TRTVAR = %qupcase(&D_TRTVAR); 
  %else %if %nrbquote(&R_TRTVAR) ne %then %let G_TRTVAR = %qupcase(&R_TRTVAR);

/*
/ Execute parameter validation specified in section 2.3.1 [of the unit
/ specification].
/
/ PLEASE NOTE: All of the following functionality shall apply when G_USAGE is
/ DD except where indicated. None of the following functionality shall apply
/ when G_USAGE is AR except where indicated.
/----------------------------------------------------------------------------*/

/*
/ Check that %upcase(&g_stype) is equal to either "XO" or "PG".
/--------------------------------------------------------------------------*/

  %if &G_STYPE ne XO and &G_STYPE ne PG %then
  %do;
    %put %str(RTE)RROR: TS_SETUP: Study type R(D)_STYPE(=&g_stype) should be equal to either XO or PG;
    %let g_abort = 1;   /* SL006 */
  %end;
  
/*
/ THE FOLLOWING PARAMETER VALIDATION IS ONLY FOR DATA DISPLAY DRIVER PROGRAMS.
/----------------------------------------------------------------------------*/

  %if &G_USAGE eq DD %then
  %do; 
  /*
  / Check that the value of "g_subjid" corresponds to a valid SAS variable
  / name, using %tu_chknames.
  /--------------------------------------------------------------------------*/

    %if %nrbquote(%tu_chknames(&G_SUBJID, VARIABLE)) ne %then
    %do;
      %put %str(RTE)RROR: TS_SETUP: Subject variable (R_SUBJID) should correspond to a valid SAS name;
      %let g_abort = 1;   /* SL006 */
    %end;

  /*
  / Check that the value of "g_centid" corresponds to a valid SAS variable name,
  / using %tu_chknames.
  /--------------------------------------------------------------------------*/

    %if %nrbquote(%tu_chknames(&G_CENTID, VARIABLE)) ne %then
    %do;
      %put %str(RTE)RROR: TS_SETUP: Centre ID variable (R_CENTID) should correspond to a valid SAS name;
      %let g_abort = 1;   /* SL006 */
    %end;

  /*
  / Check that &g_trtvar is equal to either "A" or "R".
  /--------------------------------------------------------------------------*/

    %if &G_TRTVAR ne A and &G_TRTVAR ne R %then
    %do;
      %put %str(RTE)RROR: TS_SETUP: Type of treatment variable should be either A or R;
      %let g_abort = 1;   /* SL006 */
    %end;

  /*
  / YW005: Check that &G_TRT_INPER is equal to either "Y" or "N".
  /--------------------------------------------------------------------------*/

    %if (&G_TRT_INPER ne Y) and (&G_TRT_INPER ne N) %then
    %do;
      %put %str(RTE)RROR: TS_SETUP: Value of parameter D(R)_TRT_INPER(=&G_TRT_INPER) should be either Y or N;
      %let g_abort = 1;   
    %end;
  
  /*
  / YW005: Check that &G_TRT_INPER  equals "N" when &G_STYPE is PG
  /--------------------------------------------------------------------------*/

    %if (&G_TRT_INPER eq Y) and (&G_STYPE eq PG) %then
    %do;
      %put %str(RTE)RROR: TS_SETUP: Value of parameter D(R)_TRT_INPER(=Y) should only be used when study type for the display is XO;
      %let g_abort = 1;   
    %end;

  /*
  / Check that the value of "g_dddata" is not missing.
  /--------------------------------------------------------------------------*/

    %if &G_DDDATA eq %then
    %do;
      %put %str(RTE)RROR: TS_SETUP: Directory of data display dataset (R_DDDATA) is missing;
      %let g_abort = 1;   /* SL006 */
    %end;

  /*
  / Check that the value of "g_refdata" is not missing.
  /--------------------------------------------------------------------------*/

    %if &G_REFDATA eq %then
    %do;
      %put %str(RTE)RROR: TS_SETUP: Directory of reference data (R_REFDATA) is missing;
      %let g_abort = 1;   /* SL006 */
    %end;

  /*
  / Check that the value of "g_popdata" corresponds to a valid SAS dataset
  / name, using %tu_chknames.
  /--------------------------------------------------------------------------*/

    %if %nrbquote(%tu_chknames(&G_POPDATA, DATA)) ne %then
    %do;
      %put %str(RTE)RROR: TS_SETUP: Name of population dataset (R_POPDATA) should correspond to a valid SAS name;
      %let g_abort = 1;   /* SL006 */
    %end;

  /*
  / If "g_pop" is not blank then ...                         (pj001)
  / Check that the value of "g_pop" corresponds to a valid SAS variable name,
  / using %tu_chknames.
  /--------------------------------------------------------------------------*/

    %if &G_POP ne %then 
    %do;
      %if %nrbquote(%tu_chknames(&G_POP, VARIABLE)) ne %then
      %do;
        %put %str(RTE)RROR: TS_SETUP: Name of population variable (D_POP) should correspond to a valid SAS name;
        %let g_abort = 1;   /* SL006 */
      %end;
    %end;

  /*
  / Check that &g_analy_disp is equal to either "A" or "D".
  /--------------------------------------------------------------------------*/

    %if &G_ANALY_DISP ne A and &G_ANALY_DISP ne D %then
    %do;
      %put %str(RTE)RROR: TS_SETUP: Specify (D_ANALY_DISP) whether completely re-run data display (A) or refresh titles/footnotes (D);
      %let g_abort = 1;   /* SL006 */
    %end;

  /*
  / Check that &g_userid is a non-blank text string.  SL003
  /--------------------------------------------------------------------------*/

    %if %length(&G_USERID) eq 0 %then
    %do;
      %put %str(RTE)RROR: TS_SETUP: User name (D_USERID) must be a non-blank text string;
      %let g_abort = 1;   /* SL006 */
    %end;
  
  /*
  / If G_TRTFMT is not blank, then check that it corresponds to a valid name
  / for a numeric format.
  / The value of G_TRTFMT will be considered to be invalid if any of the
  / following is true:
  /
  / 1. The total number of characters, including the dot, is greater than 9.
  / 2. The first character is not an alphabetic character or underscore.
  / 3. The characters that are after the first character and before the last
  /    character preceding the dot, are not alphanumeric or underscore.
  / 4. The last character preceding the dot is not an alphabetic character or
  /    underscore.
  / 5. The last character is not a dot.                SL008 SL009
  / YW003: Added loop so that it will check both &G_TRTFMT and &G_PTRTFMT
  /--------------------------------------------------------------------------*/

    %do n=1 %to 2;
     
      %if &n eq 1 %then %let l_trtvar=;
      %else %let l_trtvar=p;
           
      %if &&&G_&l_trtvar.TRTFMT ne %then
      %do;
       
        data _null_;
       
          length currentChar $ 1;
       
          alpha = "ABCDEFGHIJKLMNOPQRSTUVWXYZ_";
          numeric = "0123456789";
          alphaNumeric = alpha || numeric;
       
          isValid = 1;
       
          g_trtfmt = upcase("&&&g_&l_trtvar.trtfmt");
          len = length(g_trtfmt);
       
          if len gt 9 then isvalid = 0;
          else
          do n = 1 to len;
       
            currentChar = substr(g_trtfmt, n, 1);
       
            select;
              when (n eq 1) if not index(alpha, currentChar) then isValid = 0;
              when (1 lt n lt (len - 1)) if not index(alphaNumeric, currentChar) then isValid = 0;
              when (n eq (len - 1)) if not index(alpha, currentChar) then isValid = 0;
              when (n eq len) if currentChar ne "." then isValid = 0;
            end; /* select */
       
          end; /* do n = 1 to len */
       
          call symput("isValid", put(isValid, 1.));
       
        run;
       
        %if not &isValid %then
        %do;
          %put %str(RTE)RROR: TS_SETUP: g_&l_trtvar.trtfmt=&&&g_&l_trtvar.trtfmt, which is not a valid name for a SAS numeric format;
          %let g_abort = 1;     /* SL008 */
        %end;
       
     %end; /* %if &G_TRTFMT ne %then */
       
  %end; /* %do n=1 %to 2 */
     
  /*
  / Check that G_OUTFILE is not blank.            SL010
  /--------------------------------------------------------------------------*/

  %if &g_outfile eq %then 
  %do;
    %put %str(RTE)RROR: TS_SETUP: G_OUTFILE must not be blank when G_USAGE = DD.;
    %let g_abort = 1;   
  %end;

%end; /* %if &G_USAGE eq DD %then */


/*
/ THE FOLLOWING PARAMETER VALIDATION IS ONLY FOR AR DATASET CREATION PROGRAMS.
/----------------------------------------------------------------------------*/

%if &G_USAGE eq AR %then
%do;

  /*
  / Check that the value of "g_rawdata" is not missing. This check shall be
  / performed only when G_USAGE is AR
  /--------------------------------------------------------------------------*/

  %if &G_RAWDATA eq %then
  %do;
    %put %str(RTE)RROR: TS_SETUP: Directory of raw datasets (R_RAWDATA) is missing;
    %let g_abort = 1;   /* SL006 */
  %end;

  /*
  / Check that the value of "g_dmdata" is not missing. This check shall be
  / performed only when G_USAGE is AR
  /----------------------------------------------------------------------------*/

  %if &G_DMDATA eq %then
  %do;
    %put %str(RTE)RROR: TS_SETUP: Directory of DM datasets (R_DMDATA) is missing;
    %let g_abort = 1;   /* SL006 */
  %end;

%end; /* %if &G_USAGE eq AR %then */

/*
/ THE FOLLOWING PARAMETER VALIDATION IS FOR BOTH DATA DISPLAY DRIVER PROGRAMS
/ AND AR DATASET CREATION PROGRAMS.
/----------------------------------------------------------------------------*/

/*
/ Check that the value of "g_ardata" is not missing. This check shall be
/ performed regardless of the value of G_USAGE
/----------------------------------------------------------------------------*/

%if &G_ARDATA eq %then
%do;
  %put %str(RTE)RROR: TS_SETUP: Directory of AR datasets (R_ARDATA) is missing;
  %let g_abort = 1;   /* SL006 */
%end;

/*
/ Call %tu_abort if any problems have been detected.     SL008
/----------------------------------------------------------------------------*/

%if &g_abort %then
%do;
  %tu_abort()
%end;

/* Assigning Treatment variables based on the value of G_DATATYPE parameter, as per change id gg015. */

%if &G_DATATYPE eq IDSL %then
%do;
  /* 
  / YW001: Moved assignment of G_TRTCD, G_TRTGRP, etc out of %if &G_USAGE eq DD
  /----------------------------------------------------------------------------*/

  /*
  / If the global macro variable "g_trtvar" has been set to "A", then assign
  / values to global macro variables as follows:
  /   Assign the value "atrtcd" to global macro variable "g_trtcd".
  /   Assign the value "atrtgrp" to global macro variable "g_trtgrp".
  /   Assign the value "patrtcd" to global macro variable "g_ptrtcd".
  /   Assign the value "patrtgrp" to global macro variable "g_ptrtgrp".
  /   YW003: Added g_tptrtcd and g_tptrgrp
  /--------------------------------------------------------------------------*/

  %if %nrbquote(&G_TRTVAR) eq A %then
  %do;
    %let G_TRTCD    = ATRTCD;
    %let G_TRTGRP   = ATRTGRP;
    %let G_PTRTCD   = PATRTCD;
    %let G_PTRTGRP  = PATRTGRP;
    %let G_TPTRTCD  = TPATRTCD;
    %let G_TPTRTGRP = TPATRTGP;  
  %end;

  /*
  / If the global macro variable "g_trtvar" has been set to "R", then assign
  / values to global macro variables as follows:
  /   Assign the value "trtcd" to global macro variable "g_trtcd".
  /   Assign the value "trtgrp" to global macro variable "g_trtgrp".
  /   Assign the value "ptrtcd" to global macro variable "g_ptrtcd".
  /   Assign the value "ptrtgrp" to global macro variable "g_ptrtgrp".
  /--------------------------------------------------------------------------*/

  %if %nrbquote(&G_TRTVAR) eq R %then
  %do;
    %let G_TRTCD    = TRTCD;
    %let G_TRTGRP   = TRTGRP;
    %let G_PTRTCD   = PTRTCD;
    %let G_PTRTGRP  = PTRTGRP;
    %let G_TPTRTCD  = TPTRTCD;
    %let G_TPTRTGRP = TPTRTGRP;  
  %end;
%end;
%else
%do;
  %if %nrbquote(&G_TRTVAR) eq A %then
  %do;
    %let G_TRTCD    = TRTAN;
    %let G_TRTGRP   = TRTA; 
  %end;

  %if %nrbquote(&G_TRTVAR) eq R %then
  %do;
    %let G_TRTCD    = TRTPN;
    %let G_TRTGRP   = TRTP;
  %end;
%end;

/* End of change id gg015. */


/* YW002: Assign the dictionary libary name */
                                        
libname diction "&G_DICTION" access = readonly;

/* YW003: Assign global format libary name */  

libname gfmtdir "&g_gfmtdir" access = readonly;  

/*
/ THE FOLLOWING IS EXECUTED ONLY FOR DATA DISPLAY DRIVER PROGRAMS.
/----------------------------------------------------------------------------*/

%if &G_USAGE eq DD %then
%do;

  /*
  / Assign value to the global macro variable "g_dddatasetname".  The value
  / should be equal to the two level SAS name for the data display dataset,
  / ie: "DDDATA." !! scan(&g_outfile,-1,'/\').
  /--------------------------------------------------------------------------*/

  %let G_DDDATASETNAME = dddata.%scan(%nrbquote(&G_OUTFILE), -1, /\);

  /*
  / Assign value to the global macro variable "g_dddatasetnameci". The
  / value should be equal to the two level SAS name for the dataset for the
  / cell index, ie: "DDDATA." !! scan(&g_outfile,-1,'/\') !! 'CI'
  /--------------------------------------------------------------------------*/

  %let G_DDDATASETNAMECI = dddata.%scan(%nrbquote(&G_OUTFILE), -1, /\)CI;

  /*
  / Assign the appropriate value to the global macro variable "g_textfilesfx"
  / by calling the macro %tu_pagesetup.
  / A semi-colon is required after the call to TU_PAGESETUP to ensure that it
  / executes completely before the subsequent code is executed.   SL004
  /--------------------------------------------------------------------------*/

  %tu_pagesetup;

  /*
  / Check that the lengths of the user specified titles and footnotes do not
  / exceed the linesize.
  / This parameter validation can not be executed until this stage, because
  / it references the G_LS global macro variable that is assigned when the
  / TU_PAGESETUP macro is called.  SL003
  / YW005: Added condition: %if &g_dsplytyp ne F.
  /--------------------------------------------------------------------------*/
   
  %if &g_dsplytyp ne F %then 
  %do;

    %do n = 1 %to 7;
      %if %length(&&d_title&n) gt &g_ls %then
      %do;
        %put %str(RTW)ARNING: TS_SETUP: Title #&n exceeds linesize and will be truncated;
      %end;                                                           /* SL004 */
    %end;
    
    %do n = 1 %to 9;
      %if %length(&&d_foot&n) gt &g_ls %then
      %do;
        %put %str(RTW)ARNING: TS_SETUP: Footnote #&n exceeds linesize and will be truncated;
      %end;                                                           /* SL004 */
    %end;
  
  %end; /* %if &g_dsplytyp ne F */

  /*
  / If the global macro variable "g_ardata" is not missing, then assign a
  / libref, "ardata" for the directory path stored in "g_ardata".
  /  -> If G_USAGE is DD, assign libref with access eq readonly.
  /--------------------------------------------------------------------------*/

  %if &G_ARDATA ne %then
  %do;
    libname ardata "&G_ARDATA" access = readonly;
  %end;
  
  %if &G_SDTMDATA ne %then
  %do;
    libname sdtmdata "&G_SDTMDATA" access = readonly;
  %end;

  /* Creating adamdata library as per change id gg015. */

  %if &G_ADAMDATA ne %then
  %do;
    libname adamdata "&G_ADAMDATA" access = readonly;
  %end;

  /* End of change id gg015. */

  /*
  / If the global macro variable "g_dddata" is not missing, then assign a
  / libref, "dddata" for the directory path stored in "g_dddata".
  /----------------------------------------------------------------------------*/

  %if &G_DDDATA ne %then
  %do;
    libname dddata "&G_DDDATA";
  %end;

  /*
  / Check that G_POPDATA exists 
  /--------------------------------------------------------------------------*/
  
  %if not %sysfunc(exist(&g_popdata)) %then
  %do;
    %put %str(RTE)RROR: TS_SETUP: Data set R_POPDATA(=&G_POPDATA) does not exist;
    %let g_abort = 1;   
  %end;  

  /*
  / If "g_pop" is not blank then ...                            (pj001)
  / Check that the dataset variable represented by "g_pop" is a variable that
  / actually exists in the dataset represented by "g_popdata" - do this by
  / calling %tu_chkvarsexist(&g_pop, &g_popdata).
  /
  / Note that this error processing cannot be included with the prior
  / parameter validation, because it requires the libref ARDATA to be
  / assigned.
  /--------------------------------------------------------------------------*/

  %if &G_POP ne %then %do;   
     %if %nrbquote(%tu_chkvarsexist(&G_POPDATA, &G_POP)) ne %then
     %do;
       %put %str(RTE)RROR: TS_SETUP: Variable &g_pop does not exist in the dataset &g_popdata;
       %let g_abort = 1;   /* SL006 */
     %end;
  %end;

  /*
  / Call %tu_localisation.
  /----------------------------------------------------------------------------*/

  %tu_localisation

  /*
  / If &g_analy_disp is "D", then check if there is an existing data
  / display dataset. If there is not then abort using %tu_abort.
  /----------------------------------------------------------------------------*/

  %if &G_ANALY_DISP eq D %then
  %do;
    %if %sysfunc(exist(&G_DDDATASETNAME)) eq 0 %then
    %do;
      %put %str(RTE)RROR: TS_SETUP: Refresh of titles and footnotes has been requested, but there is no existing data display dataset;
      %let g_abort = 1;   /* SL006 */
    %end;
  %end; /* %if &G_ANALY_DISP eq D %then */


  /*
  / If the creation of a treatment format has been requested, then derive the
  / format using the population dataset.            
  / Note that the population dataset will first be subsetted by the population
  / variable (g_pop) and any other subsetting criteria (g_subpop) that has been
  / specified, before the treatment format is created.            SL008
  / YW003: Added call of %tu_getdata. Added derivation for period treatment
  / format &G_PTRTFMT. 
  / YW004: Removed _tempPop1_, which is assigned to dsetout1.
  /----------------------------------------------------------------------------*/
  
  /*
  / YW005: 
  / 1. If &G_STYPE eq XO and &G_TRTDATA is missing then set G_TRTDATA
  /    to ardata.trt if ardata.trt exists
  / 2. If &g_trtdata does not exist, set G_STYPE to PG before calling %tu_getdata
  /    to avoid the ERROR message.
  / 3. recover G_STYPE
  /--------------------------------------------------------------------------*/
  
  %if &G_STYPE eq XO %then
  %do;
     %if %nrbquote(&g_trtdata) eq %then %let g_trtdata=ardata.trt;
     %if not %sysfunc(exist(&g_trtdata)) %then %let G_STYPE=PG;
  %end;
    
  %tu_getdata(
     dsetin=&g_popdata,
     dsetout1=,
     dsetout2=_tempPop2_
     );

  %let G_STYPE=%qupcase(&R_STYPE);   
  %if %nrbquote(&D_STYPE) ne %then %let G_STYPE=%qupcase(&D_STYPE);;
    
  %if &G_DATATYPE eq IDSL %then
  %do;
    %let _cntr = 2;
  %end;
  %else %if &G_DATATYPE eq CDISC %then
  %do;
    %let _cntr = 1;
  %end;
  
    %do n=1 %to &_cntr;

     %if &n eq 1 %then %let l_trtvar=;
     %else %let l_trtvar=p;

     %if &&&G_&l_trtvar.TRTFMT ne %then
     %do;
      
        %if %tu_chkvarsexist(_tempPop2_, &&&g_&l_trtvar.trtcd &&&g_&l_trtvar.trtgrp) eq %then
        %do;         
         
           proc sort data = _tempPop2_ out=_tempPop_ (keep = &&&g_&l_trtvar.trtcd &&&g_&l_trtvar.trtgrp)
                     nodupkey
                     ;
             by &&&g_&l_trtvar.trtcd &&&g_&l_trtvar.trtgrp;
           run;
         
           data _tempPop_;
             set _tempPop_;
             rename &&&g_&l_trtvar.trtcd = start &&&g_&l_trtvar.trtgrp = label;
             retain fmtname;
             if _n_ eq 1 then fmtname = compress("&&&g_&l_trtvar.trtfmt", ".");
           run;
         
           proc format cntlin = _tempPop_;
           run;
           
        %end; /* %tu_chkvarsexist(&g_popdata, &&&g_&l_trtvar.trtcd &&&g_&l_trtvar.trtgrp) eq */   
         
     %end; /* %if &G_TRTFMT ne %then */
  
  %end; /* %do n=1 %to 2; */


%end; /* %if &G_USAGE eq DD %then */

/*
/ THE FOLLOWING IS EXECUTED ONLY FOR AR DATASET CREATION PROGRAMS.
/----------------------------------------------------------------------------*/

%if &G_USAGE eq AR %then
%do;

  /*
  / If the global macro variable "g_ardata" is not missing, then assign a
  / libref, "ardata" for the directory path stored in "g_ardata".
  /  -> If G_USAGE is AR, assign libref with read/write access.
  /--------------------------------------------------------------------------*/

  %if &G_ARDATA ne %then
  %do;
    libname ardata "&G_ARDATA";
  %end;
  
  %if &G_SDTMDATA ne %then
  %do;
    libname sdtmdata "&G_SDTMDATA" access=readonly;
  %end;

  /* Creating adamdata library as per change id gg015. */

  %if &G_ADAMDATA ne %then
  %do;
    libname adamdata "&G_ADAMDATA" access = readonly;
  %end;

  /* End of change id gg015. */

%end; /* %if &G_USAGE eq AR %then */

%if &G_USAGE eq SDTM %then
%do;

  /*
  / If the global macro variable "g_sdtmdata" is not missing, then assign a
  / libref, "sdtmdata" for the directory path stored in "g_sdtmdata".
  /  -> If G_USAGE is SDTM, assign libref with read/write access.
  /--------------------------------------------------------------------------*/

  %if &G_ARDATA ne %then
  %do;
    libname ardata "&G_ARDATA" access=readonly;
  %end;
  
  %if &G_SDTMDATA ne %then
  %do;
    libname sdtmdata "&G_SDTMDATA";
  %end;

  /* Creating adamdata library as per change id gg015. */

  %if &G_ADAMDATA ne %then
  %do;
    libname adamdata "&G_ADAMDATA" access = readonly;
  %end;

  /* End of change id gg015. */

%end; /* %if &G_USAGE eq SDTM %then */

/* Assigning libraries when G_DATATYPE is CDISC and G_USAGE is ADAM, as per change id gg015. */

%if &G_DATATYPE eq CDISC and &G_USAGE eq ADAM %then
%do;

  /*
  / If the global macro variable "g_adamdata" is not missing, then assign a
  / libref, "adamdata" for the directory path stored in "g_adamdata".
  /  -> If G_USAGE is ADAM, assign libref with read/write access.
  /--------------------------------------------------------------------------*/

  %if &G_ARDATA ne %then
  %do;
    libname ardata "&G_ARDATA" access=readonly;
  %end;
  
  %if &G_SDTMDATA ne %then
  %do;
    libname sdtmdata "&G_SDTMDATA" access=readonly;
  %end;

  %if &G_ADAMDATA ne %then
  %do;
    libname adamdata "&G_ADAMDATA";
  %end;

%end; /* %if &G_DATATYPE eq CDISC and &G_USAGE eq ADAM %then */
/* End of change id gg015. */

/* YW005: 
/ 1. Assign &G_TRTCD and &G_TRTGRP to G_TRTSEQCD and G_TRTSEQGRP
/ 2. If &G_TRT_INPER equals Y,  G_TRTCD = &G_TPTRTCD,G_TRTGRP = &G_TPTRTGRP 
/    G_PTRTCD =&G_TPTRTCD, G_PTRTGRP = &G_TPTRTGRP
/ 3. If &G_TRT_INPER equals N, G_TRTCD = &G_PTRTCD, G_TRTGRP = &G_PTRTGRP   
/    G_TRTSEQFMT = &G_TRTFMT, G_TRTFMT = &G_PTRTFMT
/------------------------------------------------------------------------------*/

%let G_TRTSEQCD=&G_TRTCD;
%let G_TRTSEQGRP=&G_TRTGRP;
%let G_TRTSEQFMT=&G_TRTFMT;
 
%if &G_DATATYPE eq IDSL and &G_STYPE eq XO %then
%do;
   %let G_TRTFMT=&G_PTRTFMT;     
   %if &G_TRT_INPER eq Y %then
   %do;
      %let G_TRTCD    = &G_TPTRTCD;
      %let G_TRTGRP   = &G_TPTRTGRP;    
      %let G_PTRTCD   = &G_TPTRTCD;
      %let G_PTRTGRP  = &G_TPTRTGRP;       
   %end;
   %else %do;
     %let G_TRTCD     = &G_PTRTCD;
     %let G_TRTGRP    = &G_PTRTGRP;
   %end;
%end; /* %if &G_STYPE eq XO */

/*
/ THE FOLLOWING IS EXECUTED FOR BOTH DATA DISPLAY DRIVER PROGRAMS AND AR
/ DATASET CREATION PROGRAMS
/----------------------------------------------------------------------------*/

/*
/ If the global macro variable G_RAWDATA is not missing, then assign a libref,
/ "rawdata" for the directory path stored in "g_rawdata".
/----------------------------------------------------------------------------*/

%if &G_RAWDATA ne %then
%do;
  libname rawdata "&G_RAWDATA" access = readonly;
%end;

/*
/ If the global macro variable G_DMDATA is not missing, then assign a libref,
/ "dmdata" for the directory path stored in "g_dmdata".
/----------------------------------------------------------------------------*/

%if &G_DMDATA ne %then
%do;
  libname dmdata "&G_DMDATA" access = readonly;
%end;

/*
/ If the global macro variable "g_macdirs" is not missing, then obtain the
/ current macro search path, using the %sysfunc and getoption functions,
/ concatenate this with the macro search path stored in "g_macdirs" (such
/ that the directories in "g_macdirs" are to the left of the existing
/ search path), and then re-set the sasautos option with this concatenated
/ macro search path.
/----------------------------------------------------------------------------*/

%if &G_MACDIRS ne %then
%do;

  %let CURR_PATH = %nrbquote(%sysfunc(getoption(sasautos)));

  %if %nrbquote(%substr(&CURR_PATH, 1, 1)) ne %str(%() %then
  %do;
    %put %str(RTE)RROR: TS_SETUP: Value of SASAUTOS option, obtained using GETOPTION function does not begin with '(';
    %let g_abort = 1;   /* SL006 */
  %end;
  %else
  %do;
    options sasautos = ( &G_MACDIRS %substr(&CURR_PATH, 2);
  %end;

%end; /* %if &G_MACDIRS ne %then */

/*
/ If the global macro variable G_RFMTDIR is not blank, then assign the
/ libref RFMTDIR to the directory path specified by this global macro
/ variable. However, if the value of G_RFMTDIR is blank, then assign the
/ RFMTDIR libref as
/ "/arenv/arxxxx/compound_id/study_id/reporting_id/refdata", where
/ "arxxxx", "compound_id", "study_id", and "reporting_id" are obtained
/ from the directory path specified in G_ARDATA.                  SL006 SL007
/----------------------------------------------------------------------------*/

libname rfmtdir

  %if %length(&g_rfmtdir) ne 0 %then
  %do;
    "&g_rfmtdir"
  %end;
  %else
  %do;
    "/arenv/%scan(&g_ardata, 2, /)/%scan(&g_ardata, 3, /)/%scan(&g_ardata, 4, /)/%scan(&g_ardata, 5, /)/refdata"
  %end;
  ;

/*
/ If the global macro variable G_SFMTDIR is not blank, then assign the
/ libref SFMTDIR to the directory path specified by this global macro
/ variable. However, if the value of G_SFMTDIR is blank, then assign the
/ SFMTDIR libref as "/arenv/arxxxx/compound_id/study_id/refdata", where
/ "arxxxx", "compound_id", and "study_id" are obtained from the directory
/ path specified in G_ARDATA.                                     SL006 SL007
/----------------------------------------------------------------------------*/

libname sfmtdir

  %if %length(&g_sfmtdir) ne 0 %then
  %do;
    "&g_sfmtdir"
  %end;
  %else
  %do;
    "/arenv/%scan(&g_ardata, 2, /)/%scan(&g_ardata, 3, /)/%scan(&g_ardata, 4, /)/refdata"
  %end;
  ;

/*
/ If the global macro variable G_CFMTDIR is not blank, then assign the
/ libref CFMTDIR to the directory path specified by this global macro
/ variable. However, if the value of G_CFMTDIR is blank, then assign the
/ CFMTDIR libref as "/arenv/arxxxx/compound_id/refdata", where "arxxxx"
/ and "compound_id" are obtained from the directory path specified in
/ G_ARDATA.                                                       SL006 SL007
/----------------------------------------------------------------------------*/

  libname cfmtdir

  %if %length(&g_cfmtdir) ne 0 %then
  %do;
    "&g_cfmtdir"
  %end;
  %else
  %do;
    "/arenv/%scan(&g_ardata, 2, /)/%scan(&g_ardata, 3, /)/refdata"
  %end;
  ;

/*
/ Assign the format search path, using the fmtsearch option, such that
/ librefs are searched in the following order: RFMTDIR, SFMTDIR, CFMTDIR.
/ Note that if a libref does not point to a format catalog called FORMATS,
/ then it will not be included in the format search path.              SL006
/ YW002: Added diction.
/ YW003: Changed diction to gfmtdir
/----------------------------------------------------------------------------*/

  options fmtsearch = (                                       
                     %if %sysfunc(cexist(rfmtdir.formats)) %then rfmtdir;
                     %if %sysfunc(cexist(sfmtdir.formats)) %then sfmtdir;
                     %if %sysfunc(cexist(cfmtdir.formats)) %then cfmtdir;
                     gfmtdir                         
                    );

/*
/ Assign options appropriate values for the pagesize=60 and linesize=132
/ options.
/ Also set the missing option to ' '.
/----------------------------------------------------------------------------*/

  options pagesize = 60 linesize = 132 missing = ' ';                 /* SL002 */

/* Call %tu_tidyup to remove temporary datasets.                SL008 */

  %tu_tidyup(glbmac = none)

/* Call %tu_abort if any problems have been detected. */

  %if &g_abort %then
  %do;
    %tu_abort()
  %end;

%MEND ts_setup;

