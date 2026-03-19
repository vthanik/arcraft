LIBNAME inlib XPORT "&inlib/&xpt_filename";
LIBNAME outlib "&outlib";
%MACRO ta_transport2();

  PROC PRINTTO LOG="&log" NEW;
  RUN;
       
  PROC COPY IN=inlib
            OUT=outlib;
  RUN;

%MEND ta_transport2;
%ta_transport2;
