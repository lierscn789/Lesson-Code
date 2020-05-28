data censas ;
infile 'C:\Users\yecha\Downloads\Compressed\censas.txt' truncover;
input @1 signal $ @;
length address $20;
input  address $ 3-30;
input @1 signal @;
do while (signal = 'P');
input  @3 name & $10. age Sex $;
output;/*output�Ժ����û�к����input����Զ����һ�У�����output�����signal��ֵ*/
input @1 signal @@;
/*�������output�����������������һ������*/
end;
drop signal;
run;
proc print data=censas;
run;


data censas ;
infile cards;
input @1 signal $ @@;
length address $20;
if signal = 'H' then do;
input  address $ 3-30;
do until (signal = 'H');
input  @3 name & $10. age Sex $;
output;
input @1 signal @@;/*�������output�����������������һ������*/
end;
end;
drop signal;
cards;
H  321 S.  MAIN  ST
P  MARY E  21  F
P  WILLIAM M  23  M
P  SUSAN K   3  F
H  324 S.  MAIN  ST
P  THOMAS H  79  M
P  WALTER S  46  M
P  ALICE A  42  F
P  MARYANN A  20  F
P  JOHN S  16  M
H  325A S.  MAIN  ST
P  JAMES L  34  M
P  LIZA A  31  F
P  MARGO K  27  F
;
run;

proc print data=censas;
run;

data test;
income =50000000;
expenses=38750000;
do i= 1 to 75;
income=income*1.01;
expenses=expenses*1.02;
if income <=expenses then 
leave;	
end;
run;
proc print data=test noobs;
format income expenses dollar14.2;
run;

libname elec 'C:\Users\yecha\Downloads\Compressed\�����������¶�����.xls';
run;

proc contents data=elec._all_;
run;
libname elec clear;/*�޷���ȡ*/

libname excel "C:\Users\yecha\Downloads\Compressed\�����������¶�����.xls";
proc contents data=excel._all_; run;
proc print data=EXCEL.'ˮ��������$'n;run;
libname excel clear;

PROC IMPORT OUT=WORK.water
		DATAFILE="C:\Users\yecha\Downloads\Compressed\�����������¶�����.xls"
		DBMS=EXCEL REPLACE;
	RANGE="ˮ��������$A1:BI131";
	GETNAMES=YES;
	MIXED=YES;

run;

data dl;
set water (firstobs=4);
year=input(scan(_col0,1),4.0)
month=input(scan(_col0,2),2.0)
array t(*)
run;

proc transpose data=fire out=fire2;
var F1-F65; 
run;

data fire3 ;
set fire2;
where COL1 = '����������_����' or COL1= 'ָ��';
drop _NAME_ _LABEL_ COL1 COL3 COL4;
run;

proc transpose data=fire3 out=fire2;
var COL2 COL5-COL131; 
run;

proc format;
value $missfmt ' '='Missing' other='Not Missing';  /*һ��Ҫ�ÿո�*/
value  missfmt  . ='Missing' other='Not Missing';  
run;     


proc means data=fire2 nmiss noprint ;
var COL2-COL33;
output out=miss(drop=_type_ _freq_) nmiss=;
run;


proc contents data= fire;
run;

/*data fire2;*/
/*set fire;*/
/*select (*/


data answer failed passed;
set tmp1.test_answers;
score=0;
do i= Q1,Q10;
if i= 'A' then score=score+1;
end;
do i =Q4,Q8,Q9;
if i='B' then score=score+1;
end;
do i =Q2,Q3;
if i='C' then score=score+1;
end;
do i =Q7;
if i='D' then score=score+1;
end;
do i =Q5,Q6;
if i='E' then score=score+1;
end;
drop i;
select;
when (score>=7) output passed ;
otherwise output failed; 
end;
run;

proc print data=failed ;
run;

