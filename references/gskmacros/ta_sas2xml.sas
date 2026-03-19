options symbolgen mprint mlogic;

libname foobar "&lib";

%macro ta_sas2xml;

data data1;
set foobar.&data;
run;

* Prepare the XML and output it *;
ods xml body=_webout (dynamic);
proc print data=data1 noobs;
run;
title;
ods xml close;
run;
quit;
%mend ta_sas2xml;
%ta_sas2xml;

%put _global_;
%put _local_;

