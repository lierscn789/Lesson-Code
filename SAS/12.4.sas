

%macro STATS(Dsn,Class,Vars);
title "Statistics from data set %Dsn";
proc means data=&Dsn n mean min max maxdec=1;
class &Class;
var &Vars;
run;
%mend ;

%STATS(sashelp.class,sex,height weight)


%put _user_;

libname  fit 'C:\Users\yecha\Downloads\Compressed\ʵ�鱨��4+5'; 
/*ԭ������Q2_fitness�޷����룬��������Ϊ���»��ߣ��ĳ�fitness����Զ���*/

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
/*��ԭ��һ���Ļ������װ�ԭ�����������*/
set fit.fitness;
P_TimeMile=runtime/&timemile;
P_RestPulse=rstpulse/&restpulse;
P_MaxPulse=maxpulse/&maxpulse;
run;
proc print;
run;



proc import datafile='C:\Users\yecha\Downloads\Compressed\ʵ�鱨��4+5\ָ����ϵ.xls' 
out= index
dbms=excel replace;

range="ָ����ϵ$";
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
/*select input(_016,best12.)/input(_015,best12.) , input(_017,best12.)/input(_015,best12.), input(_018,best12.)/input(_015,best12.) from work.A&i where F1="������";*/
alter table final add y2016 dec,y2017 dec,y2018 dec ;
quit;

%macro importloop ;
%do i=11 %to 25;
proc import datafile="C:\Users\yecha\Downloads\Compressed\ʵ�鱨��4+5\ԭʼ����\&&index&i.."
/*���ĩβ��.��ʾ�Զ������ļ����ͣ���˲���Ҫxls��*/
out=work.A&i
dbms=excel replace;
range="ָ��˵��$";
getnames =no;
MIXED=yes;
run;

data B&i;
set A&i(keep=F2);
if _n_ = 6 then do;
call symputx("page&i",F2);
/*һ��ʼpage&iû��˫���ţ���ʾ���ű�������������ĸ�����»��߿�ͷ*/
end;
run;
/*proc delete data=A&i;*/
/*run;*/

proc import datafile="C:\Users\yecha\Downloads\Compressed\ʵ�鱨��4+5\ԭʼ����\&&index&i.."
/*���ĩβ��.��ʾ�Զ������ļ����ͣ���˲���Ҫxls��*/
out=work.A&i
dbms=excel replace;
range="&&page&i.$";
getnames =yes;
/*����ݵ������ֵĻ�����ʱ�������������ֿ�ͷ�����Ի�ѵ�һ���ַ�����»��ߣ����Կ�����_016��ʾ*/
run;



%if &&page&i.=2 %then %do;

proc sql;
/*select input(_016,best12.)/input(_015,best12.) , input(_017,best12.)/input(_015,best12.), input(_018,best12.)/input(_015,best12.) from work.A&i where F1="������";*/
/*alter table final add y2016 dec,y2017 dec,y2018 dec ;*/


update final set y2016=(select input(cats(_016),best12.)/input(cats(_015),best12.)from work.A&i where F1="������"
) , y2017=(select input(cats(_017),best12.)/input(cats(_015),best12.)from work.A&i where F1="������"
) , y2018=(select input(cats(_018),best12.)/input(cats(_015),best12.)from work.A&i where F1="������"
) where final._COL2 = "&&index&i";	
/*�������Ҫ��˫����Ҳ�����ǵ����ţ���Ȼ�ᵱ���Ǹ�����*/
quit;
%end;



%end;

%mend ;


%importloop;


data proc 
proc import datafile="C:\Users\yecha\Downloads\Compressed\ʵ�鱨��4+5\ԭʼ����\&index1..xls"
out=apple
dbms=excel replace;

range="ָ��˵��$";
getnames =no;

run;

data test;
set A1;
keep _016;

run;

