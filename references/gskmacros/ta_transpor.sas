libname INLIB "&inlib";
libname OUTLIB xport "&outlib/&dataset..xpt";
%macro ta_transpor();

  %let dsid  = %sysfunc(open(inlib.&dataset));
  %let dataset_label = %sysfunc(attrc(&dsid,label));
  %let rc = %sysfunc(close(&dsid));

   
  data &dataset %if %length(&dataset_label) ne 0 %then (label="&dataset_label");
    ;
    set inlib.&dataset(drop=&varlist);
  run;

  proc printto log="&log" new;
  run;
       
  proc copy in=work
            out=OUTLIB
            memtype=data;
            select &dataset;
  run;

%mend ta_transpor;
%ta_transpor;
