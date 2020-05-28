cd C:\Users\yecha\Documents\金融计量\data

use hprice2a.dta ,clear
reg lprice lnox ldist rooms stratio, robust
lincom lnox-stratio //拒绝
test lnox=stratio
test rooms=0.33

estat imtest, white 

reg lprice lnox ldist rooms stratio
estat hettest ,normal

reg lprice lnox ldist rooms stratio, noconstant 
predict price_e

reg lprice lnox ldist rooms stratio 
qui predict y_hat
predict e, res
gen e2=e^2
reg e2 y_hat ,noconstant
quietly predict p1
reg lprice lnox ldist rooms stratio[aweight=1/p1] //加权最小二乘法

*等价于手动计算
gen const=1
foreach var of varlist lprice const lnox ldist rooms stratio {
	gen `var'_new =`var'/sqrt(p1)
}
reg *new,noconstant



reg lprice lnox ldist rooms stratio
estat ovtest 
estat ovtest ,rhs
estat ic
estat vif
pwcorr lprice lnox ldist rooms stratio, star(0.01)

// reg lprice lnox ldist rooms stratio
// predict lprice_l,leverage
// sum lprice_l
// sort lprice_l
// list lprice_l in -5/L

sum room 
sort room 
// list room in -5/L
return list 
scalar times=r(max)/r(mean)
dis times 

use gasoline.dta,clear
tsset year
reg lgasq lincome lgasp lpnc lpuc
predict e1 ,res
predict p1

twoway scatter e1 L.e1 || lfit e1 L.e1
// twoway (line e1 year) (line L1.e1 year)

ac e1
dwstat

predict e, res
reg e1 L.e1
eret list
mat list e(b)
scalar DW=2*(1-_b[L.e])
dis DW

*广义差分法
reg e1 L.e1 L2.e1 //二阶显著
qui reg e L1.e L2.e, nocons 
local rho1=_b[L1.e]
local rho2=_b[L2.e]
gen const =1
foreach var of varlist const lgasq lincome lgasp lpnc lpuc{
gen `var'_2=`var'-`rho1'*L.`var'-`rho2'*L2.`var'
}
reg lgasq_2 lincome_2 lgasp_2 lpnc_2 lpuc_2 const_2,nocons
dwstat 
est store Corch2

// prais lgasq lincome lgasp lpnc lpuc, corc

use consumption_china.dta , clear 

tsset year 
// dis 12*(T/100)^(1/4) 表示最大阶数
dis 12*(_N/100)^(1/4) //=8

//平稳性检验

dfuller c ,regress lag(2) trend //case 4
dfuller c ,regress lag(2) drift // case 3
dfuller c ,regress lag(2)  //case2
dfuller c ,regress lag(2) nocons //case1 

dfuller c ,regress lag(1) trend //case 4
dfuller c ,regress lag(1) drift // case 3
dfuller c ,regress lag(1)  //case2
dfuller c ,regress lag(1) nocons //case1 

*c 和y均为非平稳过程
gen lnc=log(c)
gen lny=log(y)

dfuller D.lnc ,regress lag(2) trend 
dfuller D.lnc , regress lag(0) drift //显著,认为是带漂移项的平稳序列
dfuller D.lny ,regress lag(3) drift 
varsoc D.lnc D.lny //可以发现之后1阶最好

// varsoc y c ,maxlag(4)
// var y c ,lag(1/2) dfk small 


varbasic D.lnc D.lny , lag(1)
varstable 
varstable ,graph //出现一个单位圆，如果都在单位圆内则平稳
*残差序列相关检验
varlmar 
predict e1 ,res eq(#1)
ac e1
predict e1 ,res eq(#2)
ac e2 //不存在序列相关性

*granger检验
vargranger
*发现两者互相都可以成因果关系


use pe.dta
tsset year 
*单位根检验
dis 12*(_N/100)^(1/4)
dfuller logpe ,regress lag(0) trend //无法拒绝 case4，从复杂到简单
*可见 LOGPE是平稳的！！
*因此只需要ARMA(p,q)模型即可

line logpe year  
line D.logpe year

line D2.logpe year

ac logpe  //拖尾
pac logpe //截尾，基本上可以判断是AR(1),或ARMA(1,1)

dfuller logpe
dfuller D.logpe

*通过信息准则循环生成各种模型确定为ARMA(1,1)模型







use mus08psidextract.dta

xtreg lwage exp exp2 wks ed 

reg lwage exp exp2 wks ed
est store ols
xtreg lwage exp exp2 wks ed ,fe
est store fe
xtreg lwage exp exp2 wks ed ,re
est store re

hausman fe re //原假设为随机效应优于固定效应
*Ho:  difference in coefficients not systematic 表示系数差异不存在系统性，即不同组之间系数没有差异，随机效应

local mm "ols re fe"
esttab `mm', mtitle(`mm') scalar(r2 r2_o r2_w r2_a)


