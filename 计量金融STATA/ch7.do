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





















