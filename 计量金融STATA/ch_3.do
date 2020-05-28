  sysuse auto, clear
reg price mpg weight turn

estat hettest ,normal //进行 B-P检验 nR^2服从p-1卡方分布,p极小，说明存在异方差
* tests for heteroskedasticity异方差性 Ho: Constant variance 原假设为常数方差，且与自变量无关

estat imtest, white //同样服从卡方分布
*information matrix test

sysuse nlsw88, clear
reg wage ttl_exp race age industry hours
est store ols //est为estimates的缩写，  estimates store name saves the current (active) estimation results underthe name name.

reg wage ttl_exp race age industry hours, robust //进行稳健性回归
est store robust
esttab ols robust, mtitle(OLS robust)

sysuse auto, clear
gen wei2 = weight
reg price mpg weight turn foreign [aw=1/wei2] //aw为权重
rvpplot weight //画出某个变量的残差分布图


cd "C:\Users\yecha\Documents\金融计量\ch3_data"
import excel using B2GreeneTab51.xlsx, first clear
qui reg expend age ownrent income income2
predict e , res  //用预测模型计算残差
gen e2 = e*e //计算残差平方

reg e2 income income2, noconstant //检验残差是否和自变量有关，假设残差平方是income 和income2的线性函数
qui predict p1
reg expend age ownrent income income2 [aweight=1/p1]


import excel using B2consumts.xlsx, first clear
reg lconsumption lincome
predict e, res
twoway (scatter e t) (line e t), yline(0,lp(dash) lc(blue)) legend(off) xtitle(时间序列) ysize(3) xsize(4) ////twoway是用来把两个图画在一起
graph save ts.gph, replace.


import excel using B2lutkepohl.xlsx,first clear
tsset year //把一个变量变成时间序列数据
reg lnconsum lnincome
predict e1, res
ac e1 //ac表示画 自相关图与置信区间，另一个类似命令为pac，表示偏相关图

*线性回归中就自带了t检验参数

import excel using B2lutkepohl.xlsx,first clear
tsset year
reg ln_consum ln_income
predict e1, res 
reg e1 L.e1


reg consum income 
dwstat // 查看DW统计量值，用于检验是否存在残差自相关
*DW检验，仅能用于检验AR（1）的序列相关，即是否一阶相关

import excel using data_5_1_1.xlsx, first clear
br
tsset year //时间序列的标识变量year
reg Y X

*手动算DW量
predict e, res
reg e L.e
eret list
mat list e(b)
scalar DW=2*(1-_b[L.e])
dis DW


*F检验，是否存在二阶相关性
*1阶相关检验

reg e X L.e L2.e
//L.e表示时间序列的自相关性，L表示Lag，如果要表示二阶lag则用L2.e


ereturn list //查看回归模型有哪些属性
scalar LM = e(N)*e(r2_a)

scalar p = 1 - chi2(1,LM)
dis "LM = " LM " p-value= " p

*2阶相关检验
reg e X L.e L2.e
scalar LM = e(N)*e(r2)
scalar p = 1 - chi2(2,LM) //chi2返回卡方分布值
dis "LM = " LM " p-value= " p

*广义差分法,见notebook笔记
*命令
prais Y X, corc //no converge use Cochrane-Orcutt transformation科克伦-奥科特迭代法 prais表示是Prais-Winsten调整后的迭代方法，也就是没有抛弃t=1的点
/*结果为，表明在使用该差分方法后，显著减小了自相关性。
Durbin-Watson statistic (original)    0.380898
Durbin-Watson statistic (transformed) 1.691904
*/
est store Coch
* 手动计算
* step1: 计算相关系数
qui reg Y X
qui dwstat //这里就是迭代之前的DW统计量
ret list //return list
scalar rho = 1 - r(dw)*0.5 //DW统计量约等于2(1-r)
dis rho
* step2: 转换数据y* = y - rho*y(-1)
gen cons=1
gen Y1=Y-rho*L.Y 
gen X1=X-rho*L.X
gen cons1=cons-rho*L.cons
reg Y1 X1 cons1, nocons //去除一阶自相关后的模型
est store Coch_hand
* 结果对比
esttab Coch Coch_hand, mtitles(Coch Coch_hand)

newey Y X, lag(1) //Newey稳健型估计，White估计的拓展
est store newey

*多重共线性
sysuse auto ,clear

pwcorr weight length headroom trunk turn gear_ratio ,star(0.01) //star用于标记显著性，例如0.01下认为显著标记星号


reg price weight length headroom trunk turn gear_ratio
estat vif //按照VIF从大到小排列
*VIF 膨胀因子 VIF_j = 1/(1-R2_j) 可以看到vif越大多重共线性越大


*广义矩估计实例

use hsng2.dta, clear //读入数据
des rent pcturban hsngval faminc reg2-reg4 //简单描述性分析
summarize rent pcturban hsngval faminc reg2-reg4 //简单统计分析
*rent pcturban hsngval faminc分别表示租金 人口比例 房价家庭收入 reg为地区因素
*租金作为因变量Y，其他变量作为X，随机干扰项一般跟房价会存在相关性，也就是内生性问题，把这种随机的扰动称为对租金的外来冲击
*选择faminc reg2-reg4作为工具变量，一般认为这些工具变量对租金的冲击因素不想关。即影响租金的外来因素和他们不想关。
ivregress gmm rent pcturban (hsngval = faminc reg2-reg4), wmatrix(unadjusted) 
///把内生性变量endogenous variables房价用四个工具变量代替，其中faminc是数值型，reg是0-1型,gmm的位置也可以选择例如2SLS的估计方法。对于gmm方法wmatrix表示权重矩阵的选择。unadjusted就是当做同方差
//同方差假设
est store gmm_homo

ivregress gmm rent pcturban (hsngval = faminc reg2-reg4), ///
wmatrix(robust) //异方差假设，权重矩阵为
est store gmm_het
* ///三划为连接符号

*--------------------------------------------
*检验解释变量是否具有内生性
*Hausman检验的一个假设就是若解释变量具有内生性
*包含在面板数据知识中
reg rent pcturban hsngval

/*
predict e2,residuals
reg e2 hsngval //p>|t|=1表示出现该结果的概率，无法拒绝原假设即β=0。认为不存在线性关系
reg e2 pcturban
*/


*面板数据

import excel using B7introFe.xlsx, first clear
tab id , gen(dum)
reg y x dum1 dum2 dum3, nocons
est store m_pooldum3


reg y x dum2 dum3
est store m_pooldum2

*面板固定效应估计方法
tsset id t //把id项作为时间
xtreg y x, fe   //自动设置了number of groups
est store m_fe


*用组内平均，样本平均获取β的无偏OLS估计
egen y_meanw = mean(y), by(id) /*公司内部平均*/
egen y_mean = mean(y) /*样本平均*/
egen x_meanw = mean(x), by(id)
egen x_mean = mean(x)
gen dy = y - y_meanw + y_mean
gen dx = x - x_meanw + x_mean
reg dy dx
est store m_stata //用store 来存储估计结果用restore 来加载

gen dy2=y-y_meanw
gen dx2=x-x_meanw
reg dy2 dx2 //这个方法得到的
est store m_stata_2



est table m_*, b(%6.3f) star(0.1 0.05 0.01) // m_*输出所有m开头的估计结果表，发现和之前xtreg的fe 固定效应估计结果一致

*例二
import excel using invest2.xlsx, first clear
save invest2.dta,replace
tsset id t

xtreg market invest stock, fe //输出三种类型的R2，within固定效应模型下的R，真正意义上的 between组内 overall总体

use invest2.dta, clear
tsset id t
xtreg market invest stock, re
xtreg market invest stock, fe


use invest2.dta, clear
tab id, gen(dum)
reg market invest stock
est store ols
reg market invest stock dum*, nocons
est store fe
lrtest ols fe //似然比检验，P值较小，认为拒绝原假设。似然比检验中分子为备择假设

xtreg market invest stock, re
xttest0 //进行拉格朗日乘数检验原假设为H0:σμ^2 =0即μi的方差为0，拒绝原假设认为存在个体效应，不应该使用混合回归

use xtcs.dta, clear
xtreg tl size ndts tang tobin npr, fe
est store fe
xtreg tl size ndts tang tobin npr, re
est store re
hausman fe re //两个估计存储值

******************************************


*组间系数差异的检验

sysuse "nlsw88.dta", clear
gen agesq = age*age
drop if race==3
gen black = 2.race //生成一个black的0-1变量
tab black
global xx "ttl_exp married south hours tenure age* i.industry" //age*表示所有以age开头的变量，包括了agesq ，i.表示这是一个离散变量
reg wage $xx i.race //用i.表示这是一个因子变量
reg wage i.race
keep if e(sample) // marks estimation sample

 *-分组回归 
global xx "ttl_exp married south hours tenure age* i.industry" 
reg wage $xx if black==0
est store White
reg wage $xx if black==1
est store Black


local m "White Black"
esttab `m', mtitle(`m') b(%6.3f) nogap drop(*.industry) ///
s(N r2_a) star(* 0.1 ** 0.05 *** 0.01)
//三个/表示未完待续，b表示点估计的进度，6表示总共六位，nogap表示中间不空一行

global xline "xline(0,lp(dash) lc(red*0.5))"
coefplot White Black, keep(ttl_exp married) ///
nolabels $xline ciopt(recast(rcap))
graph export "Fig01.png", replace

*研究妇女工资决定因素，即人种是否对于妇女工资有显著影响
dropvars ttl_x_black marr_x_black
global xx "ttl_exp married south hours tenure age* i.industry" //Controls
gen ttl_x_black = ttl_exp*black //交乘项
reg wage black ttl_x_black $xx //全样本回归+交乘项

*也可以不事先生成，而采用stata的因子变量表达式
reg wage i.black ttl_exp i.black#c.ttl_exp $xx //用#表示交乘，前一个必须为因子变量，后面为连续变量，c.表示连续变量
reg wage i.black##c.ttl_exp $xx //##表示包含两个变量以外包括其交互效应

/*在上述检验过程中，我们无意识中施加了一个非常严格的假设条件：只允许变量 [ttl_exp] 的系数在两组之间存在差异，而其他控制变量(如 married, south, hours 等) 的系数则不随组别发生变化。
从 -Table 1- 的结果来看, married， south, hours等变量在两组之间的差异都比较明显。 为此，我们放松上述假设，允许 married，south, hours 等变量在两组之间的系数存在差异：
*/

reg wage i.black i.black#(c.ttl_exp i.married i.south c.hours) $xx //包含了black因子变量对于所有组间有差异的变量名

*对于reg中没有与i.black交乘的变量认为在两组之间没有差异，并且干扰项在两组中具有相同的分布。当某一变量的系数在两组之间存在明显差异时，需要引入交乘项，对于两组的异方差问题则可以引入稳健分组标准误，vce(cluster black)或者选稳健标准误vce(robust)

global xx "c.ttl_exp married south c.hours c.tenure c.(age*) i.industry"
reg wage i.black##($xx) //这就是chow检验可以用 chowtest 命令快捷地完成
*上面命令可以看到所有的交乘项都拒绝了原假设即认为交乘项系数为0，因此可以认为这些变量对于wage的影响在黑人白人中没差异
chowtest wage $xx , group(black) //由于所有变量对于wage的影响不受black影响，因此这个chow检验接受原假设认为所有xx中变量对于wage的系数在blackwhite中没区别

*两者差别在于使用交乘项可以看各个变量对于工资的影响系数在黑人白人之间是否有区别？而使用chowtest得到的是一个总体的结论，即所有参数的系数是否一样。



