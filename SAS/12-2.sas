
PROC IMPORT OUT= WORK.water
DATAFILE= "C:\Users\yecha\Documents\WeChat Files\champianoship\FileStorage\File\2019-12\waterf.csv"
DBMS=CSV REPLACE;
GETNAMES=YES;
RUN;



/*数据清洗*/
/*描述统计*/
data waterpollution;
     set water;
	 where year = 2014;
run;

proc sql;
create table A3 as select mean(do) as do ,year as year from water group by year;
quit ;


SYMBOL INTERPOL=JOIN VALUE=DOT ;
proc gplot data=A3;
TITLE 'YEARLY DO LEVEL';
plot do*year/LEGEND;
run; 


proc sql;
create table work.A4 as select state as state,mean(do) as do,year as year from water
group by state,year;
quit;


SYMBOL INTERPOL=JOIN VALUE=DOT I=spline;
proc gplot data=A4;
TITLE 'YEARLY DO LEVEL';
plot do*year=state /overlay LEGEND ;
run;



proc sql;
create table work.A1 as select year as year,mean(do) as do,mean(PH) as PH,mean(BOD) as BOD,mean(NITRA) as nitra from water
group by year;
quit;

SYMBOL INTERPOL=JOIN VALUE=DOT W=1;
proc gplot data=A1;
TITLE 'YEARLY DO LEVEL';
plot BOD*year/LEGEND;
run; 
proc gplot data=A1;
TITLE 'YEARLY DO LEVEL';
plot nitra*year/LEGEND;
run;


/*数据标准化*/
proc standard data=A1 out=A2 mean=0 std=1;
  var do ph bod nitra;
  /*对这五个变量进行标准化，使它们均值为0标准偏差为1；
    输出数据集A2中含有标准化后的变量*/
run;
proc print data=A2;
run;

proc fastclus data=A2 summary maxc=4 maxiter=99
  outseed=clusterseed out=clusterresult cluster=cluster least=2;
  /*根据数据集stdcars进行k均值聚类：
    summary表示对聚类结果进行比较简短的输出；
    maxc=5表示最多分成5类；
    maxiter=99表示算法最多循环99次；
    outseed=clusterseed表示将各类别中心存储在clusterseed数据集中；
    out=clusterresult表示将各观测所属的类别存储在clusterresult数据集中；
    cluster=cluster指定在输出数据集clusterseed和clusterresult中
      记录类别的变量名为cluster；
    least=2指定Minowski距离度量中m的值为2，该值缺省为2。*/
  id state;
  /*指明数据集A2中"car"这个变量代表了各观测的ID*/
  var do ph bod nitra;
  /*指出使用数据集A2中（标准化后的）五个变量进行k均值聚类*/
run;

proc cluster data=A2 method=average pseudo outtree=tree;
/*根据数据集stdcars进行层次聚类。
  缺省使用的距离度量为欧式距离，如果要使用其他距离度量，需要先使用
    distance过程得到距离矩阵，再将其作为cluster过程的输入数据集。
  method=average指定使用平均连接法；
  pseudo指定输出伪F统计量和伪t方统计量；
  outtree=tree指定将聚类树图的信息放在tree数据集中。*/
  id state;
  /*指明数据集A2中"car"这个变量代表了各观测的ID*/
  var do ph bod nitra;
  /*使用数据集A2中（标准化后的）五个变量进行层次聚类*/
  copy state;
  /*将country这一变量从stdcars数据集中直接拷贝到tree数据集中*/
run;


proc tree data=tree ncl=5 out=out;
  /*使用前面cluster过程输出的tree数据集画聚类树图，
    同时把5个类别（由ncl=5指定）的聚类结果存储在数据集out中。*/
run;

/*主成分分析*/
proc princomp
           data = A2
           out = Work.PCA_Demo_out
           prefix = comp
           outstat = Work.PCA_Demo_stat
          ;
           var do ph bod nitra;
run ;

/*主成分得分*/



/*主成分分析
以及后续结果
*/



