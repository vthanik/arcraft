/*--------------------------------------------------------------------------+
| Macro Name    : ta_content2xml.sas
|
| Macro Version : 1
|
| SAS version   : SAS v9.1.3
|
| Created By    : Shan Lee
|
| Date          : 17-Jun-2008
|
| Macro Purpose : Write the output from PROC CONTENTS to an XML file.
|                 This macro is an updated version of ta_contents2xml.sas - 
|                 rather than creating an XML file using ODS, this macro
|                 writes the output of PROC CONTENTS directly to an XML file
|                 whose location is given by the SAS Intranet fileref '_webout'
|
| Macro Design  : Procedure style
|
| Input Parameters : The following macro variables should be assigned prior
|                    to calling this macro -
|
| NAME           DESCRIPTION                              REQ/OPT   DEFAULT
|
| LIB            Directory which stores the dataset for     Req     None
|                which PROC CONTENTS will be called.
|
| DATA           Name of dataset for which PROC CONTENTS    Req     None
|                will be called.  
|
| Output: XML file storing the output from PROC CONTENTS. The XML file will
|         be written to the SAS Intranet fileref '_webout'.
|
| Global macro variables created: none
|
|
| Macros called : none
|
| Example:
|
| sasBroker = new URL("http://hbu225.ha.uk.sbphrd.com:7143/harp/cgidev/broker.
| sh?_program=bcode.ta_contents2xml.sas&_service=pool7&_debug=0&lib=/arenv/arp
| rod/anna_play/apv10011/qqww/ardata&data=demo");
|
| **************************************************************************
| Change Log :
|
| Modified By :             
| Date of Modification :    
| New Version Number :      
| Modification ID :         
| Reason For Modification : 
|
+----------------------------------------------------------------------------*/

options symbolgen mprint mlogic;

libname foobar "&lib";

%macro ta_content2xml;

libname _webout xml;

proc contents data=foobar.&data. out=_webout.data1 noprint;
run;

title;
%mend ta_content2xml;
%ta_content2xml;

%put _global_;
%put _local_;
