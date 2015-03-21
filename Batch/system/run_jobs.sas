filename in_cmd pipe "dir D:\Batch\parms\*.run /b";

data a;
  attrib jobname length=$100;
  infile in_cmd length=len;
  input jobname $varying. len;
  filename = 'D:\Batch\parms\' || jobname;
run;

data b;
  attrib progname length=$100;
  set a;
  infile in_cmd length=len filevar=filename filename=myinfile end=done;
  do while (not done);
    input progname $varying. len;
	if progname eq: 'SCHEDULE' then do;
      time     = scan(progname,2,':');
      schedule = scan(progname,3,':');
	end;
	if progname ne: '#'        and 
       progname ne: 'SCHEDULE' then output;
  end;
run;

/****************************************************************************

DAILY
DAILY_BD
WEEKLY_1
MONTHLY_1
MONTHLYBD_1

Within dmr_calendar check the:

  business_day_of_month
  business_day_flag
  
****************************************************************************/

proc sql noprint;
  select business_day_of_month, business_day_flag into :business_day_of_month, :business_day_flag
  from   biaplat.dmr_calendar
  where  datepart(calendar_date) eq date();
quit;

%let business_day_of_month=&business_day_of_month;
%let business_day_flag=&business_day_flag;

%put business_day_of_month:....&business_day_of_month;
%put business_day_flag:........&business_day_flag;

data c;
  set b;
  
  sched = scan(schedule,1,'_');
  freq  = scan(schedule,2,'_');

  willdo = 'N';

  select (sched);
    when ('DAILY')
      do;
	    if freq eq 'BD' and "&business_day_flag" eq 'Y' or
		   freq	eq ''   then willdo='Y';
	  end;
	when ('WEEKLY')
      do;
	    if weekday(date()) eq input(freq,best.) then willdo='Y';
	  end;
	when ('MONTHLY')
      do;
	    if day(date()) eq input(freq,best.) then willdo='Y';
	  end;
	when ('MONTHLYBD')
      do;
	    if input(freq,best.) eq &business_day_of_month then willdo='Y';
	  end;
	otherwise;
  end;

  *if schedule ;
run;

data a;
  set biaplat.dmr_calendar;
  where current_load_day_flag eq 'Y';
run;


/*


filename outfile 'D:\Batch\system\run_jobs.bat';
  
data c;
   retain date_stamp;
   attrib runline length=$500;
   file outfile lrecl=1000;
   set b end=eof;
   if _n_ eq 1 then date_stamp = catx('_', put(date(),yymmddn8.), compress(put(time(),time8.),':'));

   job = scan(jobname,1,'.');
   program = scan(progname,2,'\.');
*  logfile = cats('logs\', job,'\',job,'_',program,'_#Y#m#d_#H#M#s.log');
   logfile = cats('logs\', job,'\',program,'_',date_stamp,'.log');

   runline = 'start /d D:\Batch /w D:\Batch\system\start_sas.bat';
   runline = catx(' ',runline, '-sysin', 'sascode\' || progname);
   runline = catx(' ',runline, '-sasinitialfolder', 'D:\Batch');
   runline = catx(' ',runline, '-log', logfile);
   runline = catx(' ',runline, '-logparm', '"rollover=session"');
   params  = cats('prod:job_name=', job, ':date_stamp=', date_stamp);
   runline = catx(' ',runline, '-sysparm', params);
   put runline;
   if eof then do;
     put 'exit';
   end;
run;

x "D:\Batch\system\run_jobs.bat";
