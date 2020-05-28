

%macro STATS(Dsn,Class,Vars);
title "Statistics from data set %Dsn";
proc means data=&Dsn n mean min max maxdec=1;
class &Class;
var &Vars;
run;
%mend ;

%STATS(sashelp.class,sex,height weight)


%put _user_;

libname  fit 'C:\Users\yecha\Downloads\Compressed\实验报告4+5'; 
/*原来名字Q2_fitness无法读入，可能是因为有下划线，改成fitness后可以读入*/

proc means data=fit.Fitness  mean;
var runtime rstpulse maxpulse;
output out=fit.fit;

run;

data _null_ ;
set fit.fit;
if _N_=4 then do ;
call symputx('timemile',runtime);
call symputx('restpulse',rstpulse);
call symputx('maxpulse',maxpulse);
end;
run;

data fit.fitness2;
/*跟原来一样的话很容易把原来的数据清空*/
set fit.fitness;
P_TimeMile=runtime/&timemile;
P_RestPulse=rstpulse/&restpulse;
P_MaxPulse=maxpulse/&maxpulse;
run;
proc print;
run;


data test;
infile cards;
input id a;
cards;
1   1353 
2   251 
3   5639 
4   3452197
;
run;
 

%macro order(text);


%global result;
/*这句话使得result可以在函数外使用*/
%let num0=0;
%do i= 1 %to %length(&text);
%let num&i =%substr(&text,&i,1);
%put &&num&i;
%end;
%do j=1 %to %length(&text)-1 ;
%do i=1 %to %length(&text)-1 ;
%let m=%eval(&i+1);
%if &&num&i>&&num&m %then %do ;
%let num0=&&num&i;
%let num&i=&&num&m;
%let num&m=&num0;
%end;
%end;
%end;
%let result=;
/*设置为空*/
%do i=1 %to %length(&text);
%let result=&result&&num&i;
%end;
%put &result;

%mend;

%order(43121);

%put &result;
%put &temp1;

data _null_ ;
set test;
call symputx('temp'||left(id),a);
run;
data new;
set test;
%let temp=a;
%order(&temp);
a=&result;

run;
proc print;
run;

proc import datafile='C:\Users\yecha\Downloads\Compressed\实验报告4+5\指标体系.xls' 
out= index
dbms=excel replace;

range="指标体系$";
getnames =yes;

run;	
/**/
/*PROC IMPORT OUT= WORK.subset2a*/
/*DATAFILE= "S:\Workshop\sales.xls"*/
/*DBMS=EXCEL REPLACE;*/
/*RANGE="Australia$";*/
/*GETNAMES=YES;*/
/*MIXED=NO;*/
/*SCANTEXT=YES;*/
/*USEDATE=YES;*/
/*SCANTIME=YES;*/
/*RUN;*/
options mprint;
options MCOMPILENOTE=ALL;
OPTIONS SYMBOLGEN;
data final ;
set index (keep=_col2 _col3);
call symputx('index'||left(_n_),_col2);
run;

%put _user_;

proc sql;
/*select input(_016,best12.)/input(_015,best12.) , input(_017,best12.)/input(_015,best12.), input(_018,best12.)/input(_015,best12.) from work.A&i where F1="长三角";*/
alter table final add y2016 dec,y2017 dec,y2018 dec ;
quit;

%macro importloop ;
%do i=1 %to 47;
proc import datafile="C:\Users\yecha\Downloads\Compressed\实验报告4+5\原始数据\&&&index&i.."
/*最后末尾是.表示自动加上文件类型，因此不需要xls了*/
out=work.A&i
dbms=excel replace;
range="指标说明$";
getnames =no;
MIXED=yes;
run;

data B&i;
set A&i(keep=F2);
if _n_ = 6 then do;
call symputx("page&i",F2);
/*一开始page&i没加双引号，显示符号变量名必须以字母或者下划线开头*/
end;
run;
/*proc delete data=A&i;*/
/*run;*/

proc import datafile="C:\Users\yecha\Downloads\Compressed\实验报告4+5\原始数据\&&index&i.."
/*最后末尾是.表示自动加上文件类型，因此不需要xls了*/
out=work.A&i
dbms=excel replace;
range="&&page&i.$";
getnames =yes;
/*把年份当做名字的话，此时列名不能是数字开头，所以会把第一个字符变成下划线，所以可以用_016表示*/
run;



%if &&page&i.=2 %then %do;

data work.A&i;
set work.A&i(firstobs=1 obs=1);
/*从第一行开始，读一行*/
run;

proc sql;
/*select input(_016,best12.)/input(_015,best12.) , input(_017,best12.)/input(_015,best12.), input(_018,best12.)/input(_015,best12.) from work.A&i where F1="长三角";*/
/*alter table final add y2016 dec,y2017 dec,y2018 dec ;*/


update final set y2016=(select input(cats(_016),best12.)/input(cats(_015),best12.)from work.A&i where F1="长三角"
) , y2017=(select input(cats(_017),best12.)/input(cats(_015),best12.)from work.A&i where F1="长三角"
) , y2018=(select input(cats(_018),best12.)/input(cats(_015),best12.)from work.A&i where F1="长三角"
) where final._COL2 = "&&index&i";	
/*这里必须要加双引号也不能是单引号，不然会当做是个列名*/
quit;
%end;



%end;

%mend ;


%importloop;


data proc 
proc import datafile="C:\Users\yecha\Downloads\Compressed\实验报告4+5\原始数据\&index1..xls"
out=apple
dbms=excel replace;

range="指标说明$";
getnames =no;

run;

data test;
set A1;
keep _016;

run;

/*编写一个针对excel读取的宏，对于xls文件用dbms=xls,对于xlsx文件用dbms=xlsx*/
%macro import(infile);
%if %scan(&infile,2,.)=xls %then %do ;

%put "执行第一步"；
proc import datafile="&infile"
out= work.text
dbms=xls replace;
run;
/*刚刚没有加run;所以proc import一直在执行*/
%end;
%else %if %scan(&infile,2,.)=xlsx %then %do ;
%put "执行第二步"；
proc import datafile="&infile"
out=work.test
dbms=xlsx replace;
run;
%end;
%else %do;
%put "文件名非法";
%end;

%mend;


%import(infile= C:\Users\yecha\Downloads\Compressed\实验报告4+5\指标体系.xls );


%macro homework;
data homework;
run;
%do i=1 %to 10
%mend;

data homework;
y=1;
x=2;
x1=3;

y=2;
x=3;
x1=4;
run;

%put &&index%eval(1+1);
%put &&index||cats(%eval(1+1));
%put &index11;
