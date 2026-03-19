/*-----------------------------------------------------------------------------------------------------+
| Macro Name                : tu_getproperty     
| 
| Macro Version             : 2 build 1
| 
| SAS version               : SAS v8.2 
| 
| Created By                : VIJAY B GOPALAN 
| 
| Date                      : 20-OCT-2005 
| 
| Macro Purpose             : This macro shall be used to get a graph property 
|                             from a property list. 
| 
| Macro Design              : Function Style
|
| Input Parameters          : 
| 
| NAME                 DESCRIPTION                                               REQ/OPT       DEFAULT 
| ----------------------------------------------------------------------------------------------------- 
| EQUALSIGNYN          Specify whether an "" sign is used with the keyword 
|                      specified by &KEYWORD.Valid Value: Y or N                 REQ           Y 
| 
| KEYWORD              Specifies a Property keyword. 
|                      Valid Value: a word                                       REQ           (Blank) 
| 
| PROPERTYLIST         Specifies the Property List to be searched. 
|                      Valid Value: a text string                                REQ           (Blank) 
|------------------------------------------------------------------------------------------------------- 
| 
| Output                                :        This function macro will return the string or value
| 
| Global macro variables created        :        None 
| 
| Macros called : 
| (@) tu_putglobals
| 
|
| Example:
| 		%tu_getproperty (
|				  equalsignyn=y
|				, keyword=font
|				, propertylist=color=blue device=vt420 font=swiss nobrackets
|			        );
| 
| 
|------------------------------------------------------------------------------------------------------- 
| Change Log : 
| 
| Modified By :              Barry Ashby 
| Date of Modification :     04-Apr-2006
| New Version Number :       1 build 8
| Modification ID :          bra13711
| Reason For Modification :  Previous builds (1-7) of this macro were processd through source code review
|                            only but the versions were not captured until this build.
|
| Modified by:               Yongwei Wang
| Date of modification:      02Apr2008
| New version number:        2/1
| Modification ID:           YW001
| Reason for modification:   Based on change request HRT0193
|                            1.Echo macro name and version and local/global macro                                            
|                              variables to the log when g_debug > 0   
+-------------------------------------------------------------------------------------------------------*/

%macro tu_getproperty(
          equalsignyn=Y /*Specify whether an '' sign is used with the keyword specified by &keyword.- Y/N?*/
        , keyword=      /*Specifies a Property keyword.*/ 
        , propertylist= /*Specifies the Property List to be searched.*/
        );

   /*----------------------------------------------------------------------*/
   /*                 Write details of macro start to log                  */
   /*----------------------------------------------------------------------*/

   %local MacroVersion;           
   %let MacroVersion=2 build 1;
   
   %if &g_debug GT 0 %then
   %do;

        %put ************************************************************;
        %put * Macro name: &sysmacroname,  Macro Version: &macroVersion ;
        %put ************************************************************;
        
        %put * &sysmacroname has been called with the following parameters: ;
        %put * ;
        %put _local_;
        %put * ;
        %put ************************************************************;
        
        %tu_putglobals()   /*to echo the parameter values and values of global macro variables to the log.*/
   
   %end;

   /*----------------------------------------------------------------------*/
   /*                    Set up Local Macro Variables                      */
   /*----------------------------------------------------------------------*/

    %local
        prefix                     /* used for uniquely identifying datasets created by this program*/
        ReturnCode                 /* Hold the Return value of the Macro */
        properties                 /* Hold partial of propteries */
        upcaseproperties           /* Hold upcase of &PROPERTIES */
        matchleft                  /* Hold partial of propteries */
        left                       /* Hold partial of propteries */        
        len                        /* length of the matched pattern */
        pos                        /* position of the matched pattern */
        rx1                        /* parse value of pattern match */
        rx2                        /* parse value of pattern match */
        rx3                        /* parse value of pattern match */
        ;

    %let ReturnCode=;	

    %let prefix=_getproperty;      /*Set the work dataset name prefix to _getproperty*/

    /*----------------------------------------------------------------------*/
    /*                  Parameter Validation                                */
    /*----------------------------------------------------------------------*/

    /* To change the parameter values to uppercase */

    %let equalsignyn=%upcase(&equalsignyn);
    %let keyword=%upcase(&keyword);  

    /*----------------------------------------------------------------------*/
    /*           1. Check that &EQUALSIGNYN is Y or N.                      */
    /*----------------------------------------------------------------------*/

    %if (%nrbquote(&equalsignyn) ne Y) and (%nrbquote(&equalsignyn) ne N) %then 
    %do;
        %put RTER%str(ROR): &sysmacroname: Value of parameter equalsignyn (&equalsignyn.) is invalid.;
        %put RTER%str(ROR): &sysmacroname: The valid value should be Y or N.;
        %let g_abort=1;
    %end;

    /*----------------------------------------------------------------------*/
    /*          2. Check that &KEYWORD is given                             */
    /*----------------------------------------------------------------------*/ 

    %if %nrbquote(&keyword) eq  %then  
    %do;
        %put RTER%str(ROR): &sysmacroname: Keyword (&keyword.) is blank.;
        %let g_abort=1;
    %end;

    /*----------------------------------------------------------------------*/
    /*         3. Check that &PROPERTYLIST is given                         */
    /*----------------------------------------------------------------------*/
	
    %if %nrbquote(&propertylist) eq  %then
    %do;
        %put RTER%str(ROR): &sysmacroname: Propertylist (&propertylist.) is blank.;
        %let g_abort=1;
    %end;

    /*----------------------------------------------------------------------*/
    /* if &g_abort equals 1 then goto exit                                  */
    /*----------------------------------------------------------------------*/

    %if &g_abort eq 1 %then 
    %do;
        %goto exit; 
    %end;

    /*----------------------------------------------------------------------*/
    /*                          Normal Process                              */
    /*----------------------------------------------------------------------*/

    /*----------------------------------------------------------------------*/
    /*          5. If &EQUALSIGNYN equals Y                                 */
    /*----------------------------------------------------------------------*/

    %if %nrbquote(&equalsignyn) eq Y %then   /*If &equalsignyn equals Y*/
    %do;

    /*----------------------------------------------------------------------*/
    /*  5a.Search for the pattern '{KEYWORD} = ({VALUES})|"{Value}"|VALUE'. */
    /*  5b.If the pattern is found, return what is found to the right       */
    /*      of the '=' sign.                                                */
    /*  5c.If the pattern is not found, return blank.                       */
    /*----------------------------------------------------------------------*/

        %let rx1=%sysfunc(rxparse($w+ "&keyword" $w* "="));
        %let rx2=%sysfunc(rxparse($w* "&keyword" $w* "="));
        %let rx3=%sysfunc(rxparse($q|$(10)));
        %let pos=0;
        %let len=0;                
        %let properties=&propertylist;
        
        %do %while ( %nrbquote(&properties) ne );
            /* split properties to two part: left and right part. the right part with quote strings */
            %syscall rxsubstr(rx3, properties, pos, len);               
            %if ( &pos lt 1 ) or ( &len lt 3 ) %then 
            %do;
               %let left=&properties;
               %let matchleft=&properties;
               %let properties=;
            %end;
            %else %do;               
               %if &pos gt 1 %then
                  %let left=%substr(&properties, 1, %eval(&pos - 1)); 
               %else 
                  %let left=;
                  
               %let matchleft=%substr(&properties, 1, %eval(&pos + &len - 1));  
               
               %if %eval(&pos + &len) le %length(&properties) %then
                  %let properties=%substr(&properties, %eval(&pos + &len));
               %else 
                  %let properties=;
            %end; /* %if ( &len lt 1 ) and ( &pos lt 1 ) */
            /* looking for keyword */
            %if %nrbquote(&left) ne %then            
            %do;         
               %let upcaseproperties=%upcase(&left);
               %syscall rxsubstr(rx2, upcaseproperties, pos, len);                             
               %if ( &pos gt 1 ) and ( &len gt 0 ) %then
                  %syscall rxsubstr(rx1, upcaseproperties, pos, len);
               /* If keyword is found */   
               %if ( &pos gt 0 ) and ( &len gt 0 ) %then
               %do;
                  %let left=%substr(&matchleft, %eval(&pos + &len));
                  %syscall rxsubstr(rx3, left, pos, len);                   
                  %if ( &pos eq 1 ) and ( &len ge 3 ) %then
                  %do;
                     %let ReturnCode=%substr(&left, 1, &len);
                  %end;    
                  %else %do;
                     %let ReturnCode=%scan(%nrbquote(&left), 1, %str( ));                     
                  %end;  
                  %let properties=;            
               %end; /* %if ( &pos gt 0 ) and ( &len gt 0 ) */
            %end; /* %if %nrbquote(&left) ne */  
        %end; /* %do %while ( %nrbquote(&properties) ne ) */

        %syscall rxfree(rx1);
        %syscall rxfree(rx2);
        %syscall rxfree(rx3);                                             

    %end;  /* End -if on &equalsignyn is Y  */

    /*----------------------------------------------------------------------*/
    /* 6. Otherwise,                                                        */
    /*    a.Search for the pattern '{KEYWORD}'.                             */
    /*----------------------------------------------------------------------*/

    %else	
    %do;

    /*----------------------------------------------------------------------*/
    /*  6b.If the pattern is found, return 1.                               */
    /*----------------------------------------------------------------------*/

        %if %sysfunc(indexw(%upcase(&propertylist),%upcase(&keyword))) gt 0 %then %let ReturnCode=1;

    /*----------------------------------------------------------------------*/
    /*  6c.If it is not found, return blank.                                */
    /*----------------------------------------------------------------------*/

        %else  %let ReturnCode=;

        %goto exit;

    %end;  /* End -else on &equalsignyn is not Y */

%EXIT:
    &ReturnCode

%mend tu_getproperty;
