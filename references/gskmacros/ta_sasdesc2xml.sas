/*--------------------------------------------------------------------------+
| Macro Name    : ta_sasdesc2xml.sas
|
| Macro Version : 1
|
| SAS version   : SAS v9.1.3
|
| Created By    : Shan Lee
|
| Date          : 19-Jun-2008
|
| Macro Purpose : Write the information from a SAS dataset to an XML file.
|                 This macro is an updated version of ta_sas2xml.sas - 
|                 rather than creating an XML file using ODS, this macro
|                 writes the SAS dataset directly to an XML file
|                 whose location is given by the SAS Intranet fileref '_webout'
|
| Macro Design  : Procedure style
|
| Input Parameters : The following macro variables should be assigned prior
|                    to calling this macro -
|
| NAME           DESCRIPTION                              REQ/OPT   DEFAULT
|
| LIB            Directory which stores the dataset that    Req     None
|                will be written to an XML file.
|
| DATA           Name of dataset that will be written to    Req     None
|                an XML file. 
|
| Output: XML file storing the information from a SAS dataset. The XML file
|         will be written to the SAS Intranet fileref '_webout'.
|
| Global macro variables created: none
|
|
| Macros called : none
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

%macro ta_sasdesc2xml;

libname _webout xml;

data _webout.data1;
  set foobar.&data;
run;

title;

%mend ta_sasdesc2xml;
%ta_sasdesc2xml;

%put _global_;
%put _local_;

