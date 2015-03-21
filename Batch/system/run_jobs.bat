start /d D:\Batch /w D:\Batch\system\start_sas.bat -sysin sascode\Job1\first_program.sas -sasinitialfolder D:\Batch -log logs\Job1\first_program_20100714_200531.log -logparm "rollover=session" -sysparm prod:job_name=Job1:date_stamp=20100714_200531 -rsasuser
start /d D:\Batch /w D:\Batch\system\start_sas.bat -sysin sascode\Job1\second_program.sas -sasinitialfolder D:\Batch -log logs\Job1\second_program_20100714_200531.log -logparm "rollover=session" -sysparm prod:job_name=Job1:date_stamp=20100714_200531 -rsasuser
exit
