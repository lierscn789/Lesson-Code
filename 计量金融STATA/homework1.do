cd C:\Users\yecha\Documents\金融计量 
import excel "C:\Users\yecha\Documents\金融计量\IPO.xlsx", sheet("原始数据") firstrow
*ssc install nmissing 
nmissing //无缺失
/*
gen dum=0 if 上市板块=="中小板"
replace dum =1 if 上市板块=="主板"
replace dum =2 if 上市板块=="创业板"
上述这一段也可以用recode来进行。
*/

encode 上市板块,gen(BK_dum) //把原来的变量变成分类变量，取值为1,2,3，生成数字-文字对应表
*转换为分类变量后可以加入regress中

*想法2
tab 上市板块 ,gen(dum)


stepwise, pe(0.05):reg 首日回报率 首日换手率 大盘涨跌 发行价 上市前收入增长率 dum1 dum2 //之所以这里不能加上dum3是因为dum3完全由dum1 和dum2决定，会引起共线性。

*--------------------周末效应---------------
clear 
import excel "C:\Users\yecha\Documents\金融计量\weekend_effects.xlsx", sheet("table") firstrow
tab weekday ,gen(dum)
reg R dum1 dum2 dum3 dum4


drop if R==0  //drop varlist用于去掉列, drop if 用于去掉观测值
reg R dum1 dum2 dum3 dum4


*-----------------------
clear
import excel "C:\Users\yecha\Documents\金融计量\Chow_test.xls", sheet("Sheet1") firstrow

*ssc install chowreg
*这是老师的做法，和我的想法差不多一致
chowreg INDEX GDP, dum(15) type(1) // dum表示 Number of First Period Observations，作为第一期
*type1表示 Y = X + D0 其中D0在第一期取0，这是第二期的影响因素。type2表示 Y = X + DX 其中DX表示D0的所有交乘项

reg GDP INDEX

mean INDEX //得到指数平均值为1600，以此为界分成两组
summarize INDEX,d
return list p50 //中位数为1362

gen dum=0
replace dum=1 if INDEX >1362

gen dum1= INDEX>1362
gen dum2= INDEX<1362

replace dum1 = dum1*INDEX
replace dum2= dum2*INDEX

regress GDP dum1 dum2 
test dum1 = dum2
 