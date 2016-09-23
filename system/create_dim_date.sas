libname cntl 'D:\Batch\sasdata\Control';

filename in url 'http://data.gov.au/dataset/b1bc6077-dadd-4f61-9f8c-002ab2cdff10/resource/a24ecaf2-044a-4e66-989c-eacc81ded62f/download/australianpublicholidays-201617.csv';

data cntl_public_holidays (drop=date_text);
    attrib date_text        length=$10.
           date             informat=yymmdd8. format=date9.
           holiday_name     length=$50.
           information      length=$200.
           more_information length=$200.
           applicable_to    length=$50.;

    infile in dsd firstobs=2 lrecl=500;

    input date_text holiday_name information more_information applicable_to;

    if date_text ne 'TBC' then date = input(date_text, yymmdd8.);
run;

data cntl_public_holidays_1 (drop=end i applicable_to hol more_information information);

    set cntl_public_holidays;

    i = 1;
    do until(end='Y');
        hol = scan(applicable_to, i);
        if hol = ''    then end = 'Y';

        if hol = 'NAT' then nat = 1;
        if hol = 'QLD' then qld = 1;
        if hol = 'NSW' then nsw = 1;
        if hol = 'TAS' then tas = 1;
        if hol = 'VIC' then vic = 1;
        if hol = 'WA'  then wa  = 1;
        if hol = 'ACT' then act = 1;
        if hol = 'SA'  then sa  = 1;
        i = i + 1;
    end;

run;

proc summary nway data=cntl_public_holidays_1 (where=(date ne .));
    class date;
    var   nat qld nsw tas vic wa act sa;
    output out=cntl_public_holidays_2 (drop=_type_ _freq_) sum=;
run;

data cntl_public_holidays_2 (drop=i nat qld nsw tas vic wa act sa);

    attrib date format=date9.;

    array hol_flag {8} $ 1 national_holiday_flag 
                           qld_holiday_flag
                           nsw_holiday_flag
                           tas_holiday_flag
                           vic_holiday_flag
                           wa_holiday_flag
                           act_holiday_flag
                           sa_holiday_flag;
    array hol_ind {8}      nat qld nsw tas vic wa act sa;


    set cntl_public_holidays_2;



    do i = 1 to 8;
        if hol_ind{i} ne . then hol_flag{i} = 'Y';
    end;

run;

data dates;
    attrib date                      format=date9.
           day_name                  format=$10.
           qld_business_day_of_month length=8
           qld_business_day_flag     format=$1.
           weekend_flag              format=$1.
           weekday_flag              format=$1.;

    do date = '01jan2016'd to '31dec2026'd;
        day_name = left(put(date, downame.));
        if weekday(date) eq 1 or weekday(date) eq 7 then do;
            weekend_flag = 'Y';
            weekday_flag = '';
        end;
        else do;
            weekend_flag = '';
            weekday_flag = 'Y';
        end;
        output;
    end;
run;

data cntl.dim_date;
    merge dates
          cntl_public_holidays_2;
        by date;

    if weekday_flag eq 'Y' and (national_holiday_flag eq '' and qld_holiday_flag eq '') then qld_business_day_flag = 'Y';

    if day(date) eq 1 then day_no = .;

    if qld_business_day_flag eq 'Y' then do;
        day_no + 1;
        qld_business_day_of_month = day_no;
    end;
run;

