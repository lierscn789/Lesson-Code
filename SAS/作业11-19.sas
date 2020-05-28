proc sql;
create table A1 ( year integer ,max decimal(10) , min decimal(10) , mean decimal(10) ,std decimal(10) ,median decimal(10) ) ;
insert into  A1 (year, max,min,mean,std,median) select distinct year(Date),max(AIR),min(air),mean(air),std(air) ,median(air) from sashelp.air 
group by year(DATE);
select month(date)as m ,year(date) from sashelp.air 
group by year(date)
having air>mean(air);
quit;

data air ;
set sashelp.air ;
year =year(date);
run;

proc means data=work.air max min mean std median ;
var air;
class year ;
output out=a2 max= min= mean= std= median=/autoname ;
run;

proc print data=a2;
run;

proc print data= A1;
run;

data score;
infile 'C:\Users\yecha\Downloads\Compressed\实验报告3\rawdata.txt';
input @1 id 10. @15 name $6. ;
input;
run;

proc sql;
create table random (id1 integer ,name1 varchar(6), id2 integer ,name2 varchar(6));
insert into random
select * from score as a cross join score as b  cross join score as c where  a.id ne b.id and b.id ne c.id and a.id ne c.id ;
 ;

run;

proc surveyselect data=random method=srs out=result n=1;
run;
proc print data=score;
run;
