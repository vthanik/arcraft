options symbolgen mprint mlogic;

libname foobar "&lib";

%macro ta_contents2xml;

proc contents data=foobar.&data. out=data1 noprint;
run;

* Prepare the XML and output it *;
ods xml body=_webout (dynamic);
proc print data=data1 noobs;
run;
title;
ods xml close;
run;
quit;
%mend ta_contents2xml;
%ta_contents2xml;

%put _global_;
%put _local_;

