x 'cd E:\SAS\final project\';

*read in the data;
data h1b_kaggle;
infile 'h1b_kaggle.csv' firstobs=2 DSD missover;
length case_status $ 50 employer_name $ 50  soc_name  $50 job_title  $100 worksite $100 full_time_position $50;
input id ?? case_status $  employer_name $   soc_name  $ job_title  $ full_time_position $ prevailing_wage ?? year ??  worksite $ lon ?? lat ??;
run;

*some transformation and filtering;
data h1b_kaggle;
set h1b_kaggle;
employer_name=upcase(employer_name);
job_title=upcase(job_title);
case_status=upcase(case_status);
soc_name=upcase(soc_name);
worksite=upcase(worksite);
where case_status = 'CERTIFIED';
run;

*section 1 general analysis;

proc sgplot data=h1b_kaggle;
	vbar year/group = year groupdisplay=cluster;
  	yaxis label = 'num of apps';
  	xaxis grid label = 'year' discreteorder=data;
run;

proc sql outobs=10;
	create table top_ten_employer_list as
	select employer_name, count(*) as total_apps
	from h1b_kaggle
	group by employer_name
	order by total_apps desc;
quit;

proc sql;
	create table employer_pie as
	select
    (case when employer_name = any(select employer_name from top_ten_employer_list) then 'top 10' else 'the rest' end) as if_top_10
	from h1b_kaggle;
quit;


proc gchart data=employer_pie;
   pie if_top_10 /
              percent=arrow
			  value = none
              slice=arrow
			  noheading 
              plabel=(font='Albany AMT/bold' h=1.3 color=depk);
run;
quit; 

proc sql;
	create table top_ten_employer as
	select *
	from h1b_kaggle
	where employer_name in (select employer_name from top_ten_employer_list);
quit;

proc sql;
	create table top_ten_employer_share as
	select employer_name, year, count(*)/85000 as share
	from top_ten_employer
    group by employer_name, year;
quit;

proc sgplot data=top_ten_employer_share;
	hbar employer_name/ response=share group = year groupdisplay=cluster grouporder=data;
  xaxis label = '% share of 85000 cap';
  yaxis grid label = 'EMPLOYER';
run;

proc sgplot data=top_ten_employer;
	hbar employer_name/ group = year groupdisplay=cluster grouporder=data;
  xaxis label = 'NUM OF APPLICATIONS';
  yaxis grid label = 'EMPLOYER';
run;

proc sql outobs=10;
	create table top_ten_job_title as
	select job_title, count(*) as total_apps, median(prevailing_wage) as median_wage
	from top_ten_employer
	group by job_title
	order by total_apps desc;
quit;

proc sql;
	create table top_ten_job as
	select *
	from top_ten_employer a
	inner join top_ten_job_title b
	on a.job_title = b.job_title
	where a.job_title in (select job_title from top_ten_job_title);
quit;

proc sort data = top_ten_job;
by DESCENDING median_wage;
run;

proc sgplot data=top_ten_job;
	hbar job_title/ categoryorder=respdesc;
  xaxis label = 'NUM OF APPLICATIONS';
  yaxis grid label = 'JOB TITLE';
run;

proc sgplot data=top_ten_job;
hbox prevailing_wage / category=job_title;
  xaxis label = 'WAGE' max = 150000;
  yaxis grid label = 'JOB TITLE' discreteorder=data;
run;

data top_software;
set h1b_kaggle;
where (job_title contains 'PROGRAMMER' or
	  job_title contains 'COMPUTER' or
	  job_title contains 'SOFTWARE' or
	  job_title contains 'SYSTEMS' or
	  job_title contains 'DEVELOPER' ) and
	  (employer_name contains 'IBM' or
       employer_name contains 'INFOSYS' or
employer_name contains 'WIPRO' or
employer_name contains 'DELOITTE' or
employer_name contains 'AMAZON' or
employer_name contains 'GOOGLE' or
employer_name contains 'MICROSOFT' or
employer_name contains 'FACEBOOK' or
employer_name contains 'TATA');
if find(employer_name,'IBM','i') ge 1 then employer_name = 'IBM';
if find(employer_name,'AMAZON','i') ge 1 then employer_name = 'AMAZON';
if find(employer_name,'MICROSOFT','i') ge 1 then employer_name = 'MICROSOFT';
if find(employer_name,'FACEBOOK','i') ge 1 then employer_name = 'FACEBOOK';
if find(employer_name,'DELOITTE','i') ge 1 then employer_name = 'DELOITTE';
if find(employer_name,'GOOGLE','i') ge 1 then employer_name = 'GOOGLE';
if find(employer_name,'INFOSYS','i') ge 1 then employer_name = 'INFOSYS';
if find(employer_name,'WIPRO','i') ge 1 then employer_name = 'WIPRO';
if find(employer_name,'TATA','i') ge 1 then employer_name = 'TATA';
run;

proc sql;
	create table top_software_median as
	select employer_name, count(*) as total_apps, median(prevailing_wage) as median_wage
	from top_software
	group by employer_name;
quit;

proc sql;
	create table top_software_sorted as
	select *
	from top_software a
	inner join top_software_median b
	on a.employer_name = b.employer_name;
quit;

proc sort data = top_software_sorted;
by DESCENDING median_wage;
run;
      
proc sgplot data=top_software_sorted;
hbox prevailing_wage / category=employer_name;
  xaxis label = 'WAGE' max = 200000;
  yaxis grid label = 'COMPANY NAME' discreteorder=data;
run;
	
*section 2 location based analysis;
data h1b_state;
set h1b_kaggle;
city = scan(worksite, 1, ',');
state = scan(worksite, -1, ',');
run;

*top 10 state;
proc sql outobs=10;
	create table top_10_state_list as
	select state, count(*) as total_apps, median(prevailing_wage) as median_wage
	from h1b_state
	group by state
	order by total_apps desc;
quit;

proc print data=top_10_state_list;
run;

proc sql;
	create table state_pie as
	select
    (case when state = any(select state from top_10_state_list) then 'top ten' else 'the rest' end) as if_top_10
	from h1b_state;
quit;


proc gchart data=state_pie;
   pie if_top_10 /
              percent=arrow
			  value = none
              slice=arrow
			  noheading 
              plabel=(font='Albany AMT/bold' h=1.3 color=depk);
run;
quit; 


proc sql;
	create table top_10_state as
	select *
	from h1b_state a
	inner join top_10_state_list b
	on a.state = b.state;
run;


proc sort data=top_10_state;
by DESCENDING total_apps;
run;

proc sgplot data=top_10_state;
	hbar state/group = year groupdisplay=cluster;
  	xaxis label = 'NUM OF APPLICATIONS';
  	yaxis grid label = 'state' discreteorder=data;
run;

proc sgplot data=top_10_state;
	hbar state/response=prevailing_wage stat=median group = year groupdisplay=cluster;
  	xaxis label = 'median wage';
  	yaxis grid label = 'state' discreteorder=data;
run;

*TOP 20 CITY;
proc sql outobs=20;
	create table top_20_city_list as
	select worksite, count(*) as total_apps, median(prevailing_wage) as median_wage
	from h1b_state
	group by worksite
	order by total_apps desc;
quit;

proc sql;
	create table city_pie as
	select
    (case when worksite = any(select worksite from top_20_city_list) then 'top 20' else 'the rest' end) as if_top_20
	from h1b_state;
quit;


proc gchart data=city_pie;
   pie if_top_20 /
              percent=arrow
			  value = none
              slice=arrow
			  noheading 
              plabel=(font='Albany AMT/bold' h=1.3 color=depk);
run;
quit; 


proc sql;
	create table top_20_city as
	select *
	from h1b_state a
	inner join top_20_city_list b
	on a.worksite = b.worksite;
run;


proc sort data=top_20_city;
by DESCENDING total_apps;
run;

proc sgplot data=top_20_city;
	hbar worksite/group = year groupdisplay=cluster;
  	xaxis label = 'NUM OF APPLICATIONS';
  	yaxis grid label = 'city' discreteorder=data;
run;

proc sgplot data=top_20_city;
	hbar worksite/response=prevailing_wage stat=median group = year groupdisplay=cluster;
  	xaxis label = 'median wage';
  	yaxis grid label = 'city' discreteorder=data;
run;

*focusing on texas;
proc sql;
	create table h1b_tx as 
	select *
	from h1b_kaggle
	where lon is not null and lat is not null and worksite like '%TEXAS';
quit;

*top 5 tx city;
proc sql outobs=5;
	create table top_5_tx_city_list as
	select worksite, count(*) as total_apps, median(prevailing_wage) as median_wage
	from h1b_tx
	group by worksite
	order by total_apps desc;
quit;

proc sql;
	create table tx_city_pie as
	select
    (case when worksite = any(select worksite from top_5_tx_city_list) then 'top 5 cities' else 'the rest' end) as if_top_5
	from h1b_tx;
quit;

proc gchart data=tx_city_pie;
   pie if_top_5 /
              percent=arrow
			  value = none
              slice=arrow
			  noheading 
              plabel=(font='Albany AMT/bold' h=1.3 color=depk);
run;
quit; 

proc sql;
	create table top_5_tx_city as
	select *
	from h1b_tx a
	inner join top_5_tx_city_list b
	on a.worksite = b.worksite;
run;

proc sort data=top_5_tx_city;
by DESCENDING total_apps;
run;

proc sgplot data=top_5_tx_city;
	hbar worksite/group = year groupdisplay=cluster;
  	xaxis label = 'NUM OF APPLICATIONS';
  	yaxis grid label = 'city' discreteorder=data;
run;

proc sgplot data=top_5_tx_city;
	hbar worksite/response=prevailing_wage stat=median group = year groupdisplay=cluster;
  	xaxis label = 'median wage';
  	yaxis grid label = 'city' discreteorder=data;
run;

*top tx employer;
proc sql outobs=20;
	create table top_tx_employer_list as
	select employer_name, count(*) as total_apps, median(prevailing_wage) as median_wage
	from h1b_tx
	group by employer_name
	order by total_apps desc;
quit;

proc sql;
	create table tx_employer_pie as
	select
    (case when employer_name = any(select employer_name from top_tx_employer_list) then 'top 20 employers' else 'the rest' end) as if_top
	from h1b_tx;
quit;


proc gchart data=tx_employer_pie;
   pie if_top /
              percent=arrow
			  value = none
              slice=arrow
			  noheading 
              plabel=(font='Albany AMT/bold' h=1.3 color=depk);
run;
quit; 


proc sql;
	create table top_tx_employer as
	select *
	from h1b_tx a
	inner join top_tx_employer_list b
	on a.employer_name = b.employer_name;
run;


proc sort data=top_tx_employer;
by DESCENDING total_apps;
run;

proc sgplot data=top_tx_employer;
	hbar employer_name/group = year groupdisplay=cluster;
  	xaxis label = 'NUM OF APPLICATIONS';
  	yaxis grid label = 'city' discreteorder=data;
run;

proc sgplot data=top_tx_employer;
	hbar employer_name/response=prevailing_wage stat=median group = year groupdisplay=cluster;
  	xaxis label = 'median wage';
  	yaxis grid label = 'city' discreteorder=data;
run;

*tx h1b jobs on maps
data tx_map; set mapsgfk.US_STATES;
if statecode='TX';
if density < 3;
flag = 1;
run;

proc sql;
	create table h1b_tx_by_location as 
	select worksite, lon as long, lat, count(*) as total_apps, median(prevailing_wage) as median_wage
	from h1b_tx
	where lon is not null and lat is not null
	group by worksite,lon,lat;
quit;

data comb;
set tx_map h1b_tx_by_location;
run;


proc gproject data=comb out=comb_projected project=gall
eastlong degrees latlong dupok;
id statecode;
run;

data map anno;
  set comb_projected;
  if flag=1 then output map;
  else output anno;
run;

data anno1; set anno;
length function $8 color $20;
xsys='2'; ysys='2'; hsys='3'; when='a';
function='pie'; style='psolid'; rotate=360; size=sqrt(total_apps/3.14)*0.07;
color='aFFFF0077';
output;
if worksite in ('HOUSTON, TEXAS','DALLAS, TEXAS', 'AUSTIN, TEXAS', 'SAN ANTONIO, TEXAS') then do;
	function='label'; position='2';
    style=''; rotate=.; size=2; color='red';
    text=worksite; 
    output;
end;
run;

proc gmap map=map data=map anno=anno1;
id statecode;
choro segment / levels=1 nolegend coutline=black ;
run;
quit;

*data science related analysis;
*see all the data science related jobs;
data ds_h1b;
set h1b_state;
where job_title contains 'DATA SCIENTIST' or 
      job_title contains 'QUANTITATIVE ANALYST'  or
	  job_title contains 'DATA ANALYST'  or
job_title contains 'BUSINESS ANALYST'  or
job_title contains 'DATABASE ADMINISTRATOR'  or
job_title contains 'DATA ARCHITECT'  or
job_title contains 'DATA ENGINEER'  or
job_title contains 'STATISTICIAN'  or
job_title contains 'MACHINE LEARNING'  or
job_title contains 'DEEP LEARNING' ;
if find(job_title,'DATA SCIENTIST','i') ge 1 then job_title = 'DATA SCIENTIST';
if find(job_title,'QUANTITATIVE ANALYST','i') ge 1 then job_title = 'QUANTITATIVE ANALYST';
if find(job_title,'DATA ANALYST','i') ge 1 then job_title = 'DATA ANALYST';
if find(job_title,'BUSINESS ANALYST','i') ge 1 then job_title = 'BUSINESS ANALYST';
if find(job_title,'DATABASE ADMINISTRATOR','i') ge 1 then job_title = 'DATABASE ADMINISTRATOR';
if find(job_title,'DATA ARCHITECT','i') ge 1 then job_title = 'DATA ARCHITECT';
if find(job_title,'DATA ENGINEER','i') ge 1 then job_title = 'DATA ENGINEER';
if find(job_title,'STATISTICIAN','i') ge 1 then job_title = 'STATISTICIAN';
if find(job_title,'MACHINE LEARNING','i') ge 1 then job_title = 'MACHINE LEARNING';
if find(job_title,'DEEP LEARNING','i') ge 1 then job_title = 'DEEP LEARNING';
run;

proc sgplot data=ds_h1b;
Vbar job_title/ group = year groupdisplay=cluster;
  yaxis label = 'NUM OF APPLICATIONS';
  xaxis grid label = 'job_title';
run;

proc sgplot data=ds_h1b;
Vbar job_title/ response =prevailing_wage stat=median group = year groupdisplay=cluster;
  yaxis label = 'median wage';
  xaxis grid label = 'job_title';
run;

*see the percentage of ds h1b by year;
proc sql;
	create table h1b_ds_or_not as
	select a.*, case when b.id is null then 'non-ds' else 'ds' end as if_ds
	from h1b_state a
	left join ds_h1b b
	on b.id = a.id;
quit;

proc sort data=h1b_ds_or_not;
by year;                     
run;
 
proc freq data=h1b_ds_or_not noprint;
by year;                    
tables if_ds / out=FreqOut;   
run;
 
title "100% Stacked Bar Chart";
proc sgplot data=FreqOut;
vbar year / response=Percent group=if_ds groupdisplay=stack;
xaxis discreteorder=data;
yaxis grid values=(0 to 100 by 10) label="Percentage of all applications";
run;

*only focus on three main types DS DE ML;
data h1b_data_science;
set h1b_kaggle;
where upcase(job_title) contains 'DATA SCIENTIST' or upcase(job_title) contains 'DATA ENGINEER' or upcase(job_title) contains 'MACHINE LEARNING';
if find(job_title,'DATA SCIENTIST','i') ge 1 then job_title = 'DATA SCIENTIST';
if find(job_title,'DATA ENGINEER','i') ge 1 then job_title = 'DATA ENGINEER';
if find(job_title,'MACHINE LEARNING','i') ge 1 then job_title = 'MACHINE LEARNING';
run;

proc sgplot data=h1b_data_science;
Vbar job_title/ group = year groupdisplay=cluster;
  yaxis label = 'NUM OF APPLICATIONS';
  xaxis grid label = 'job_title';
run;

proc sgplot data=h1b_data_science;
vbox prevailing_wage / category=job_title group=year;
   xaxis label="Job Title";
   yaxis label="Wage" max = 200000;
   keylegend / title="Year";
run; 

/*Total_apps and median_wage by industry*/
proc sql;
    create table data_science_by_industries as
    select soc_name, 
           count(*) as Total_Apps,
           median(prevailing_wage) as Median_wage
    from h1b_data_science
	where soc_name NE 'NA'
	group by soc_name
	having Total_Apps > 100
    order by Median_wage desc;
quit;


/*plot 8*/
proc sql outobs=10;
	create table top_10_industry_list as
	select soc_name, count(*) as total_apps
	from h1b_data_science
	where soc_name NE 'NA'
	group by soc_name
	order by total_apps desc;
quit;


proc sql;
	create table top_10_industry_apps as
	select *
	from h1b_data_science
	where soc_name in (select soc_name from top_10_industry_list);
quit;


proc sgplot data=top_10_industry_apps;
	hbar soc_name/ group = year groupdisplay=cluster;
  xaxis label = 'NUM OF APPLICATIONS';
  yaxis grid label = 'INDUSTRY';
run;

proc sgplot data=top_10_industry_apps;
	hbar soc_name/ response=prevailing_wage stat=median group = year groupdisplay=cluster;
  xaxis label = 'MEDIAN WAGE(USD)';
  yaxis grid label = 'INDUSTRY';
run;


*top ds employer;
proc sql outobs=20;
	create table top_ds_employer_list as
	select employer_name, count(*) as total_apps, median(prevailing_wage) as median_wage
	from h1b_data_science
	group by employer_name
	order by total_apps desc;
quit;

proc sql;
	create table top_ds_employer_pie as
	select
    (case when employer_name = any(select employer_name from top_ds_employer_list) then 'top 20 employers' else 'the rest' end) as if_top
	from h1b_data_science;
quit;


proc gchart data=top_ds_employer_pie;
   pie if_top /
              percent=arrow
			  value = none
              slice=arrow
			  noheading 
              plabel=(font='Albany AMT/bold' h=1.3 color=depk);
run;
quit; 


proc sql;
	create table top_ds_employer as
	select *
	from h1b_data_science a
	inner join top_ds_employer_list b
	on a.employer_name = b.employer_name;
run;


proc sort data=top_ds_employer;
by DESCENDING total_apps;
run;

proc sgplot data=top_ds_employer;
	hbar employer_name/group = year groupdisplay=cluster;
  	xaxis label = 'NUM OF APPLICATIONS';
  	yaxis grid label = 'EMPLOYER' discreteorder=data;
run;

proc sgplot data=top_ds_employer;
	hbar employer_name/response=prevailing_wage stat=median group = year groupdisplay=cluster;
  	xaxis label = 'median wage';
  	yaxis grid label = 'EMPLOYER' discreteorder=data;
run;


*ds by location;
proc sql;
	create table h1b_by_location as 
	select worksite, lon as long, lat, count(*) as total_apps, median(prevailing_wage) as median_wage
	from h1b_data_science
	where lon is not null and lat is not null
	group by worksite,lon,lat;
quit;

proc sql outobs=10;
    create table ds_top_ten_location_list as
	select worksite
	from h1b_by_location
	order by total_apps desc, median_wage desc;
quit;

proc sql;
	create table ds_top_ten_location as
	select *
	from h1b_data_science
	where worksite in (select * from ds_top_ten_location_list);
quit;

proc print data=ds_top_ten_location(obs=10);
run;
proc sgplot data=ds_top_ten_location;
	hbar worksite/  group = year groupdisplay=cluster grouporder=data;
  xaxis label = 'Total_Apps';
  yaxis grid label = 'LOCATION';
run;

proc sgplot data=ds_top_ten_location;
	hbar worksite/  response=prevailing_wage stat=median group = year groupdisplay=cluster grouporder=data;
  xaxis label = 'Median Wage';
  yaxis grid label = 'LOCATION';
run;
 
*see the top locations on map;
data my_map; set mapsgfk.US_STATES;
if state ne 2 and state ne 15 and state ne 72;
if density < 3;
flag = 1;
run;

data comb;
set my_map h1b_by_location;
run;


proc gproject data=comb out=comb_projected project=gall
eastlong degrees latlong dupok;
id statecode;
run;

data map anno;
  set comb_projected;
  if flag=1 then output map;
  else output anno;
run;

data anno1; set anno;
length function $8 color $20;
xsys='2'; ysys='2'; hsys='3'; when='a';
function='pie'; style='psolid'; rotate=360; size=sqrt(total_apps/3.14)*0.5;
color='aFFFF0077';
output;
if worksite = 'SEATTLE, WASHINGTON' then do;
	function='label'; position='2';
    style=''; rotate=.; size=2; color='red';
    text=worksite; 
    x=x+70; 
	y=y-30;
    output;
end;
if worksite ='NEW YORK, NEW YORK' then do;
	function='label'; position='2';
    style=''; rotate=.; size=2; color='red';
    text=worksite; 
    x=x+35; 
    output;
end;
if worksite ='SAN FRANCISCO, CALIFORNIA' then do;
	function='label'; position='2';
    style=''; rotate=.; size=2; color='red';
    text=worksite; 
    x=x+100; 
    output;
end;
run;


proc gmap map=map data=map anno=anno1;
id statecode;
choro segment / levels=1 nolegend coutline=black ;
run;
quit;

*ds jobs in TX;
proc sql;
	create table DS_TX as 
	select *
	from h1b_data_science
	where lon is not null and lat is not null and worksite like '%TEXAS';
quit;

proc print data=DS_TX;
run;

proc sgplot data=DS_TX;
	hbar worksite/  response=total_apps;
  xaxis label = 'Total Apps';
  yaxis grid label = 'LOCATION';
run;

proc sgplot data=DS_TX;
	hbar worksite/  response=median_wage;
  xaxis label = 'Median Wage';
  yaxis grid label = 'LOCATION';
run;


