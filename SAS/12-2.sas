
PROC IMPORT OUT= WORK.water
DATAFILE= "C:\Users\yecha\Documents\WeChat Files\champianoship\FileStorage\File\2019-12\waterf.csv"
DBMS=CSV REPLACE;
GETNAMES=YES;
RUN;



/*������ϴ*/
/*����ͳ��*/
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


/*���ݱ�׼��*/
proc standard data=A1 out=A2 mean=0 std=1;
  var do ph bod nitra;
  /*��������������б�׼����ʹ���Ǿ�ֵΪ0��׼ƫ��Ϊ1��
    ������ݼ�A2�к��б�׼����ı���*/
run;
proc print data=A2;
run;

proc fastclus data=A2 summary maxc=4 maxiter=99
  outseed=clusterseed out=clusterresult cluster=cluster least=2;
  /*�������ݼ�stdcars����k��ֵ���ࣺ
    summary��ʾ�Ծ��������бȽϼ�̵������
    maxc=5��ʾ���ֳ�5�ࣻ
    maxiter=99��ʾ�㷨���ѭ��99�Σ�
    outseed=clusterseed��ʾ����������Ĵ洢��clusterseed���ݼ��У�
    out=clusterresult��ʾ�����۲����������洢��clusterresult���ݼ��У�
    cluster=clusterָ����������ݼ�clusterseed��clusterresult��
      ��¼���ı�����Ϊcluster��
    least=2ָ��Minowski���������m��ֵΪ2����ֵȱʡΪ2��*/
  id state;
  /*ָ�����ݼ�A2��"car"������������˸��۲��ID*/
  var do ph bod nitra;
  /*ָ��ʹ�����ݼ�A2�У���׼����ģ������������k��ֵ����*/
run;

proc cluster data=A2 method=average pseudo outtree=tree;
/*�������ݼ�stdcars���в�ξ��ࡣ
  ȱʡʹ�õľ������Ϊŷʽ���룬���Ҫʹ�����������������Ҫ��ʹ��
    distance���̵õ���������ٽ�����Ϊcluster���̵��������ݼ���
  method=averageָ��ʹ��ƽ�����ӷ���
  pseudoָ�����αFͳ������αt��ͳ������
  outtree=treeָ����������ͼ����Ϣ����tree���ݼ��С�*/
  id state;
  /*ָ�����ݼ�A2��"car"������������˸��۲��ID*/
  var do ph bod nitra;
  /*ʹ�����ݼ�A2�У���׼����ģ�����������в�ξ���*/
  copy state;
  /*��country��һ������stdcars���ݼ���ֱ�ӿ�����tree���ݼ���*/
run;


proc tree data=tree ncl=5 out=out;
  /*ʹ��ǰ��cluster���������tree���ݼ���������ͼ��
    ͬʱ��5�������ncl=5ָ�����ľ������洢�����ݼ�out�С�*/
run;

/*���ɷַ���*/
proc princomp
           data = A2
           out = Work.PCA_Demo_out
           prefix = comp
           outstat = Work.PCA_Demo_stat
          ;
           var do ph bod nitra;
run ;

/*���ɷֵ÷�*/



/*���ɷַ���
�Լ��������
*/



