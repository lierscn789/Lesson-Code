cd C:\Users\yecha\Documents\金融计量
import excel using data.xlsx,sheet(Sheet1) firstrow clear
browse
order id  时间
gen date=ym(year,month)
format date %tm
xtset id date 
rename 收盘价 price
gen lp=ln(price)
gen R=D.lp
keep id date 名称 R
save data.dta,replace

*导入上证指数和无风险利率
import excel using data.xlsx,sheet(Sheet2) firstrow clear
gen date=ym(year,month)
format date %tm
tsset date  
rename 收盘价 price
drop if missing(Rf)

gen lp=ln(price)
gen Rm=D.lp
gen Rc=Rm-Rf
save RmRf.dta ,replace

*merge data(横向合并)
use data.dta ,clear
merge m:1 date using RmRf.dta //合并数据,m:1表示多对一,标识变量为date
xtset id date 
drop _merge
save data_all.dta,replace

*生成beta
use data_all,clear
order id date R Rc
xtset id date 
gen R1=R-Rf //表示超额收益率
drop if missing(R1,Rc)

xtdes //数据心态
by id:gen Num_obs=_N //计算每家公司的连续观测书
drop if Num_obs <48 //删除观测数小于48个的公司
xtdes //其中1111表示有观测

summarize id, d

*为了节省时间删除一些公司
keep if id <600068


rollreg R1 Rc,move(48) stub(Be) //48个月滚动进行回归stub(Be)存储估计结果的beta
//分别输出α的beta、标准误，常数项的beta，每一个数据都是用前面48个月的数据计算得到

drop if missing(Be_Rc) //每家公司前面47个月的没有beta值
xtset id date 
order id date Be_Rc
gen LBe_Rc=L.Be_Rc 
order id date Be_Rc LBe_Rc
save temp.dta ,replace


*生成组合
use temp.dta ,clear 
drop if missing(LBe_Rc)
duplicates drop id year ,force //duplicates drop 根据id 和year把重复的值删除 ,这样以后只保留每个公司每一年的一个数据，只要id 和year同时相同，就删除
keep id year LBe_Rc
save temp2.dta,replace

use temp.dta ,clear 
drop LBe_Rc
merge m:1 id year using temp2.dta 
keep if _merge ==3 //表示保留完全匹配的
order id date LBe_Rc //这里的操作表示每个银行每一年的beta值都一样，不会按照月份变化
xtset id date 
drop _merge 

*按照beta值划分为5个组，如果更多数据可以分为20组

gen Beta_group=.
forvalues i=2009/2018{
xtile temp=LBe_Rc if year==`i',nquantile(5) //xtile表示做分位数
replace Beta_group=temp if year==`i'
drop temp 
}

order id date LBe_Rc Beta_group

*计算每个组合的收益率(算术平均值)
sort date Beta_group
bysort date Beta_group :egen R_Beta_group=mean(R)


*计算每个组合超额收益率-(被解释变量)
gen Ri_Rf =R_Beta_group-Rf

duplicates drop date Beta_group,force
keep date year month  Rc Ri_Rf R_Beta_group Beta_group
save data_all_2.dta ,replace


*5个组合回归分析

use data_all_2.dta,clear 
sort Beta_group date 

*用每组的超额收益率对市场组合超额收益率进行回归

statsby _b _se , by(Beta_group):regress Ri_Rf Rc
gen t_cons =_b_cons /_se_cons
list Beta_group t_cons //good
save temp3.dta ,replace

*------------
*-第二步：CAPM横截面
*------------
use data_all_2, clear
sort Beta_group date

bysort Beta_group: egen Ri_Rf_mean=mean(Ri_Rf) 

//求每组超额收益率的样本平均值

duplicates drop Beta_group,force
keep Ri_Rf_mean Beta_group
merge 1:1 Beta_group using temp3

*用每组的超额收益率的样本均值对每组的beta进行回归
reg Ri_Rf_mean _b_Rc  // so bad. 

*理论预期是 _b_Rc的回归系数显著为正, 常数项显著为零。而中国市场不符合理论预期，说明
* CAPM模型在中国市场没有通过检验。





cd C:\Users\yecha\Documents\金融计量
import excel using data_a.xlsx,sheet(Sheet2) firstrow clear
gen date=ym(year,month)
format date %tm
tsset date 
rename 收盘价 price 
gen lnp=ln(price)
gen Rm=D.lnp //计算上证指数收益率
drop if year==2019
drop if year==2004
save RmRf.dta,replace 

import excel using data_a.xlsx ,sheet(Sheet1) firstrow clear
gen date=ym(year,month)
format date %tm
save data.dta ,replace 

use data.dta,clear 
xtset id date  //panel data
rename 收盘价 p
gen lp=ln(p)
gen R=D.lp //计算每只股票月度收益率

drop if missing(R)
drop if year==2019
drop if year==2004
merge m:1 date using RmRf.dta
drop _merge
save data_after.dta ,replace


************因子构造

use data_after.dta ,clear

sort year id 
gen Rm_Rf=Rm-Rf //计算市场超额收益率
gen size1=总市值 if month==12 //获取每只股票每年末的总市值
by year id:egen size=mean(size1) //让每只股票的每个月的总市值变成年末总市值

gen PM1=市净率 if month==12 //获取每只股票年末市净率
by year id :egen PM=mean(PM1)

drop if missing(size ,PM)

gen BM=1/PM

//按照size的中位数分为S和B两类
by year:egen size_median =median(size)
gen group_size ="S" if size<size_median
replace  group_size="B" if size >=size_median


//对账面市值比BM分类，前30%为高账面市值比H，后30%为低账面L


sort year group_size
by year group_size :egen BM30=pctile(BM) ,p(30)
by year group_size :egen BM70=pctile(BM),p(70)

gen group_BM="L" if BM<=BM30
replace group_BM="M" if BM>BM30 & BM<=BM70
replace group_BM="H" if BM>BM70


gen group_sizeBM=group_size +group_BM


//计算SMB

sort date id 
by date :egen SBM_temp1=mean(R) if group_sizeBM=="SH"
by date :egen SBM_temp2=mean(R) if group_sizeBM=="SM"
by date :egen SBM_temp3=mean(R) if group_sizeBM=="SL"
by date :egen SBM1=mean(SBM_temp1)
by date :egen SBM2=mean(SBM_temp2)
by date :egen SBM3=mean(SBM_temp3)
gen SSBM=(SBM1+SBM2+SBM3)/3


by date:egen BBM_temp1=mean(R) if group_sizeBM=="BH"
by date:egen BBM_temp2=mean(R) if group_sizeBM=="BM"
by date:egen BBM_temp3=mean(R) if group_sizeBM=="BL"
by date :egen BBM1=mean(BBM_temp1)
by date :egen BBM2=mean(BBM_temp2)
by date :egen BBM3=mean(BBM_temp3)
gen SBBM=(BBM1+BBM2+BBM3)/3


drop SBM_temp* BBM_temp*

drop SBM1 SBM2 SBM3 BBM1 BBM2 BBM3
gen SMB=SSBM-SBBM



*计算第二个因子HML
by date :egen H1_temp=mean(R) if group_sizeBM=="BH"
by date :egen H2_temp=mean(R) if group_sizeBM=="SH"
by date: egen H1=mean(H1_temp)
by date: egen H2=mean(H2_temp)
gen H=(H1+H2)/2

by date :egen L1_temp=mean(R) if group_sizeBM=="BL"
by date :egen L2_temp=mean(R) if group_sizeBM=="SL"

by date:egen L1=mean(L1_temp)
by date:egen L2=mean(L2_temp)
gen L=(L1+L2)/2


drop H1_temp H2_temp L1_temp L2_temp
drop  H1 H2 L1 L2 
gen HML=H-L



*因变量分成25组 5*5
//按照总市值划分为5个组
gen size_group=.
forvalues i=2005/2018{
xtile temp=size if year==`i',nquantile(5)
replace size_group=temp if year==`i'
drop temp
}
//每个总市值组合下按照BM划分为5个组合
gen BM_group=.
forvalues i=2005/2018{
forvalues j=1/5{
xtile temp=BM if year==`i' & size_group ==`j' ,nquantile(5)
replace BM_group=temp if year==`i' & size_group==`j'
drop temp
}
}
gen comBM=size_group*10+BM_group //组合几号生成

sort date comBM
bysort date comBM: egen R_comBM=mean(R)

//计算每个组合的超额收益率
gen Ri_Rf=R_comBM-Rf
save dataout.dta,replace


*数据导出

use dataout.dta ,clear 
keep date year month Rm_Rf SMB HML Ri_Rf comBM
duplicates drop date comBM,force //删除重复值 
save data_all.dta,replace  
// export excel "factors.xlsx",sheet("Sheet1") firstrow 


use data_all.dta,clear

sort comBM date 
statsby _b _se ,by(comBM) :regress Ri_Rf Rm_Rf SMB HML






