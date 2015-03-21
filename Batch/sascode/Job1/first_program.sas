/******************************************************************************************
**                                                                                       **
**                                                                                       **
**                                                                                       **
**                                                                                       **
******************************************************************************************/

%let env = %scan(&sysparm, 1, %str(:));

%macro parse_parms;
  %global sysparm;
  
  %let i = 2;
  
  %let pair = %scan(&sysparm, &i, %str(:));
  
  %do %while (%str(&pair) ne %str());
    %let var_name = %scan(&pair, 1, %str(=));
	%let var_value = %substr(&pair, (1 + %index(&pair, %str(=))));
	
    %global &var_name;
	%let &var_name=&var_value;
	%let i = %eval(&i + 1);
	%let pair = %scan(&sysparm, &i, %str(:));
  %end;

%mend parse_parms;

%parse_parms;

%put JOB_NAME=&job_name;

data _null_;
  set sashelp.vmacro end=eof;
  where scope eq         'GLOBAL' and
        name  contains   '_'      and
		name  not eq: 'SQL'       and
		name  not eq: 'SYS';
  if _n_ eq 1 then put '**************** User macro variables ****************';
  put name '= ' value;
  if eof then put '******************************************************';
run;


* Include initialisation code;
* %include "...../demo_init.sasinc";

* Print macro variables;
* %print_macro_vars(inc_text=%str(_));

* Output HTML PDF;
filename htmlfile "reports\&job_name\first_program_&date_stamp..html";
filename pdffile  "reports\&job_name\first_program_&date_stamp..pdf";

* Assign library;
libname job1lib "sasdata\&job_name";


options orientation=landscape;

ods listing close;
ods markup  file=htmlfile (title="Test Job")
            style=sasweb
		    tagset=tagsets.xhtml;
ods printer pdf file=pdffile
            style=sasweb
			stylesheet='
			notoc;

proc report nowd data=sashelp.class;
  column sex height weight;
  define sex / display;
  define height / display;
  define weight / display;
run;

ods printer close;
ods markup close;
ods listing;  
  
