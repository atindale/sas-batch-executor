options ls=120
        emailsys=smtp
        emailauthprotocol=login
        emailpw=<password>
        emailid="<email_address>";

%let sysparm = prod:job_name=Job1:date_stamp=20100714_144138;

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

data _null_;
    set sashelp.vmacro end=eof;
    where scope eq         'GLOBAL' and
          name  contains   '_'      and
          name  not eq:    'SQL'    and
          name  not eq:    'SYS';
    if _n_ eq 1 then put '**************** User macro variables ****************';
    put name '= ' value;
    if eof      then put '******************************************************';
run;

/******************************************************************************************
** Find the email address                                                                **
******************************************************************************************/

filename in_mail "D:\Batch\parms\&job_name..mail";

data mail;
    attrib mail_to     length=$50 informat=$50.
           destination length=$50 informat=$50.;
    infile in_mail length=len lrecl=1000 end=done missover;
    input mail_to destination;
    if mail_to ne: '#' then output;
run;

/******************************************************************************************
** Read the log file names                                                               **
******************************************************************************************/

filename in_dir pipe "dir D:\Batch\logs\&job_name\*&date_stamp..log /b";

data log (drop=i filename);
    attrib log1-log10 length=$50;
    retain i 0 log1-log10;
    array log{10} $ log1-log10;
    attrib filename length=$200;
    infile in_dir length=len end=eof;
    input filename $varying. len;
    i = i + 1;
    log{i} = filename;
    if eof then do;
        total_logs = i;
        output;
    end;
run;

/******************************************************************************************
** Read the report file names                                                            **
******************************************************************************************/

filename in_dir pipe "dir D:\Batch\reports\&job_name\*&date_stamp.* /b";

data reports (drop=i filename);
    attrib report1-report10 length=$50;
    retain i 0 report1-report10;
    array report{10} $ report1-report10;
    attrib filename length=$200;
    infile in_dir length=len end=eof;
    input filename $varying. len;
    i = i + 1;
    report{i} = filename;
    if eof then do;
        total_reports = i;
        output;
    end;
run;

/******************************************************************************************
** Concatenate together                                                                  **
******************************************************************************************/

data cleanup;
    set log;
    set reports;
run;

/******************************************************************************************
** Parse the log files                                                                   **
******************************************************************************************/

data parse_log (drop=i log1-log10 total_logs);
    attrib log1-log10 length=$50;
    array log{10} $ log1-log10;

    attrib logline  length=$250
           myinfile length=$200
           logfile  length=$200;
    set log;

    do i = 1 to total_logs;
        filename = "D:\Batch\logs\&job_name\" || log{i};

        infile in_cmd length=len filevar=filename filename=myinfile end=done;

        line_num = 1;

        do while (not done);
            input logline $varying. len;
            logfile = myinfile;
            if logline eq: 'ERROR: '   or
               logline eq: 'WARNING: ' then output;
            line_num = line_num + 1;
        end;
    end;
run;

/******************************************************************************************
** Email the recipients                                                                  **
******************************************************************************************/

filename reports email "alan@flexiblesoftware.com.au"; 

data x;
    attrib attach length=$400;

    file reports;
    if _n_ eq 1 then set cleanup;
    set mail;

    array report{10} $ report1-report10;
    array log{10}    $ log1-log10;

    put '!EM_TO! ' mail_to;
    put "!EM_SUBJECT! &job_name Completed";
    put " ";
    put "&job_name has completed. Reports are attached.";
    put " ";
    put "Environment:....&env";
    put "Job Name:.......&job_name";
    put "Date Stamp:.....&date_stamp";
    put " ";

    if destination eq '*' then do;
        /* Attach logs and reports to the email */

        attach = '!EM_ATTACH! (';

        do i = 1 to total_reports;
            attach = trim(attach) || ' "' || "D:\Batch\reports\&job_name\" || trim(report{i}) || '"';
        end;

        do i = 1 to total_logs;
            attach = trim(attach) || ' "' || "D:\Batch\logs\&job_name\" || trim(log{i}) || '" ';
        end;

        attach = trim(attach) || " )";

        put attach;

        /* Loop through the errors in the logs */

        put " ";

        do obsnum=1 to last;
            if obsnum eq 1 then do;
                put 'The following errors and/or warnings were found:';
                put " ";
            end;
            set parse_log point=obsnum nobs=last;
            put "Line number " line_num "in log file: " logfile;
            put logline;
            put " ";
        end;

        put " ";

    end;

    if destination eq 'reports' then do;
        attach = '!EM_ATTACH! (';

        do i = 1 to total_reports;
            attach = trim(attach) || ' "' || "D:\Batch\reports\&job_name\" || trim(report{i}) || '"';
        end;

        attach = trim(attach) || " )";

        put attach;
    end;

    put '!EM_SEND!';
    put '!EM_NEWMSG!';
    put '!EM_ABORT!';      
run;

filename reports email "alan@flexiblesoftware.com.au"; 

data x;
    file reports;
    put '!EM_TO! alan@flexiblesoftware.com.au';
    put "!EM_SUBJECT! &job_name Completed";
    put " ";
    put "&job_name has completed. Reports are attached.";
    put " ";
    put "Environment:....&env";
    put "Job Name:.......&job_name";
    put "Date Stamp:.....&date_stamp";
    put " ";
    put '!EM_SEND!';
    put '!EM_NEWMSG!';
    put '!EM_ABORT!'; 
run;
