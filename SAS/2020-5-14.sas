libname intern 'C:\Users\yecha\Documents\WeChat Files\champianoship\FileStorage\File\2020-05\DATA' ;

libname intern clear;

proc contents data=intern._all_ ;
run;


/*data report;*/
/*set intern.prh_report;*/
/*x=datepart(report_time);*/
/*date_as_num = putn(x,'yymmn6.'); */
/*/*put x=b8601dn.;*/*/
/*run;*/
/*太大了原来的数据集 */;


data Pda_5yearstatus;
set intern.Pda_5yearstatus(obs=2000);
X=input(months !! "01", yymmdd8.);
run;
data prh_report;
set intern.prh_report(obs=100);
date=datepart(REPORT_TIME);
run;


proc print;
run;

proc sql;
select 
quit;

proc sql;
/*select datepart(report_time) from intern.prh_report ; */

select input(months !! "01", yymmdd8.) from Pda_5yearstatus;
quit;

proc sql;
select month(datepart(report_time)) from intern.prh_report;
quit;


data work.hebin;
merge work.prh_report work.pda_5yearstatus;
by report_no;
keep report_no X PAY_BACK_TYPE months date;
run;

data num;
set hebin;
where intck('month',X,date)<=24 and PAY_BACK_TYPE='1';
run;

proc sort data=num;
by months report_no;
run;

data num3;
set num;
count=1;
run;
proc summary data=num3;
by months;
var count;
output out=out sum=sumcount;
run;

/*要求已经进行过sort*/
data num2;
set num;
by months;
retain count;
if first.months then count=0;
count=count+1;
if last.months then output;
keep months count;
run;

data num3;
set num;
by  months report_no;
retain count ;
/*if first.report_no then maxcount=0;*/
if first.months then do  ;
count=0;
end;
count=count+1;
if last.months then output;
keep months count report_no;
run;

proc sort data=num3;
run;
data num3;
set 
run;


data intern.max;
set intern.num;
m=max(num);
run;




proc print;
run;

proc sql;
select * from work.pda_5yearstatus as a inner join work.prh_report as b 
on a.report_no=b.report_no ;
quit;

proc sql;
select b.report_time, a.months from work.pda_5yearstatus as a inner join work.prh_report as b 
on a.report_no=b.report_no ;
quit;

proc sql;
select *,intck('month', input(a.months !! "01", yymmdd8.),datepart(b.report_time))as dmonth from work.pda_5yearstatus as a , work.prh_report as b 
where a.report_no=b.report_no order by dmonth ;
quit;

proc sql;
select *,intck('month', input(a.months !! "01", yymmdd8.),datepart(b.report_time))as dmonth from work.pda_5yearstatus as a , work.prh_report as b 
where a.report_no=b.report_no order by dmonth desc;
quit;

proc sql;
/*select  a.*,intck('month', input(a.months !! "01", yymmdd8.),datepart(b.report_time))as dmonth from work.pda_5yearstatus as a , work.prh_report as b */
/*where a.report_no=b.report_no and a.PAY_BACK_TYPE='1' having dmonth<=24 order by dmonth desc;*/

/*select distinct months,count(months) as number,report_no from (select  a.*,intck('month', input(a.months !! "01", yymmdd8.),datepart(b.report_time))as dmonth from work.pda_5yearstatus as a , work.prh_report as b */
/*where a.report_no=b.report_no and a.PAY_BACK_TYPE='1' having dmonth<=24  )group by months;*/

select  max(number) from (select  months,count(months) as number,report_no from (select  a.*,intck('month', input(a.months !! "01", yymmdd8.),datepart(b.report_time))as dmonth from work.pda_5yearstatus as a , work.prh_report as b 
where a.report_no=b.report_no and a.PAY_BACK_TYPE='1' having dmonth<=24  )group by months);
quit;


%macro question1 ;
%let N1=3;
%let N2=6;
%let N3=9;
%let N4=12;
%let N5=24;
%let N6=36;
%let N7=48;
%let N8=60;
proc sql;
create table final (N integer, result integer);
quit;

%do i=1 %to 8;

proc sql;
select  max(number) into:result&i from (select  months,count(months) as number,report_no from (select  a.*,intck('month', input(a.months !! "01", yymmdd8.),datepart(b.report_time))as dmonth from work.pda_5yearstatus as a , work.prh_report as b 
where a.report_no=b.report_no and a.PAY_BACK_TYPE='1' having dmonth<=&&N&i..  )group by months);
/*update final set N=&&N&i..,result=&&result&i..;*/
insert into final(N,result) values(&&N&i..,&&result&i..);
quit;

%put '第&i次运行';
%put &&result&i..;


%end;

%mend;

%question1


data Pda_basicinfo;
set intern.Pda_basicinfo(obs=2000);
run;

proc sql;
select count(dmonth) from (select a.open_date,b.PAY_BACK_TYPE,intck('month',a.open_date,input(b.months !! "01", yymmdd8.))as dmonth  from work.Pda_basicinfo as a ,work.pda_5yearstatus as b where a.report_no=b.report_no and b.PAY_BACK_TYPE ne 'C'
and b.PAY_BACK_TYPE ne 'D' and b.PAY_BACK_TYPE ne 'G' and b.PAY_BACK_TYPE ne 'M' and b.PAY_BACK_TYPE ne 'N' and b.PAY_BACK_TYPE ne 'Z'
having dmonth<=6) ;
quit;



proc sql;
select distinct PAY_BACK_TYPE  from intern.pda_5yearstatus ;
quit;
