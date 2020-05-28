cd D:\第二学期\金融计量学\操作数据\ch6_data
*=======================
* ARCH 模型 help arch
*=======================
*
* 金融时间序列的基本特征
* ARCH 模型的基本设定
* ARCH 效应的检验
* ARCH 模型的估计
* 模型优劣的评估

*---------
* 简 介
*---------
* 金融时序的基本特征：尖峰厚尾、波动丛聚性
* 大幅波动跟随着大幅波动，平静跟随着平静


* 例1：沪市大盘指数时序图
use B6_hs_index.dta, clear
global xd "xlabel(,valuelabel)"
cap drop t
tostring date, gen(tt)
encode tt, gen(t)
tsset t

* 2001-2008
line index_hu t, $xd /// 
ytitle("ShangHai Stock Makket Index") ///
xti("") xlabel(1(250)1800)

* 2007-2008
line index_hu t if date>20070101, $xd ///
ytitle("ShangHai Stock Makket Index") ///
xti("")


* 收益波动

* 上证综指收益率时序图
line rr_hu t, $xd xtitle("Returns of Shanghai stock market Index") ///
yline(0,lw(thick)) ytitle("") xlabel(1(330)1800)
graph save rhu, replace
* 深证成指收益率时序图
line rr_shen t, $xd xtitle("Returns of Shenzheng sotck market Index") ///
yline(0,lw(thick)) ytitle("") xlabel(1(330)1800)
graph save rshen, replace


* 沪深300指数收益率时序图
line rr_hs300 t, $xd xtitle("Returns of Shen-Hu300 Index") ///
yline(0,lw(thick)) ytitle("") xlabel(1(330)1800)
graph save hs300, replace

graph combine rhu.gph rshen.gph hs300.gph, col(1) ///
caption("Data Source: CCER, 20010101-20080430")


* 上证综指及其绝对值的时序图
gen abs_rr_hu = abs(rr_hu)
line rr_hu t, $xd ytitle(Returns) xlabel(1(330)1800) xtitle("")
graph save rr_hu.gph, replace
line abs_rr_hu t, $xd ytitle(|Returns|) xlabel(1(330)1800) xtitle("")
graph save rr_hu_abs.gph, replace

graph combine rr_hu.gph rr_hu_abs.gph, row(2)

* 分布特征： t 分布，尖峰厚尾
sum rr_hu, detail
histogram rr_hu, normal
kdensity rr_hu, normal lw(thick)
histogram rr_shen, normal
histogram rr_hs300, normal

* 正态分布检验
qnorm rr_hu, grid /*Q-Q图，对尾部特征比较敏感*/
pnorm rr_hu, grid /*对中间部位比较敏感*/

* 综合处理
* ssc install archqq
archqq rr_hu /*需要下载*/

*-------------
*== ARCH 模型 Engle (1982)
*-------------
 

*-- 基本思想：采用自回归过程(AR(p))来描述干扰项的方差序列

*-- 模型设定：
*
* y_t = x_t*b + e_t e_t -- N(0,s2_t)
*
* Var(e_t) = sigma2_t 
* = h_t
* = c + a_1*e2_t-1 + a_2*e2_t-2 + ... + a_p*e2_t-p
* -----------------------------------------------
* AR(p) 条件方差
*
* 其中，sigma2 = sigma^2 ； e2 = e^2

*-- 估计： MLE

*-- 检验ARCH效应： Engle(1982)
* 
* Step1: reg y x (OLS), 得到残差序列 e_t ；
* Step2: reg e2_t e2_t-1 ... e2_t-p (OLS)，得到 R2 ；
* Step3: 构造统计量 LM = T*R2 -- Chi2(p) ；


*== 例2：上证综指收益率的 ARCH(p) 模型
use B6_hs_index.dta, clear

*- 检验 ARCH 效应是否存在：archlm 命令
regress rr_hu
archlm, lag(1/20)
 
regress rr_hu L(1/3).rr_hu
archlm, lag(1/20)

* 计算过程解析
cap drop e
cap drop e2
reg rr_hu
predict e, res
gen e2 = e^2
reg e2 L(1/10).e2
local LM = e(N)*e(r2)
dis in g "chi2(" in y "`e(df_m)'" in g ") = " in y %6.3f `LM' ///
in g " p-value = " in y %6.4f chi2(`LM', e(df_m))


*- 估计： arch 命令
arch rr_hu, arch(1/6)
arch rr_hu, arch(1/10)
archqq
* 评论: (1) ARCH 模型通常需要设定较多的滞后阶数
* (2) 通过加入常数项，我们基本上控制了偏度，
* 但峰度问题仍然没有得到很好的控制 
 
 
*- 确定最佳滞后阶数
* 信息准则 AIC BIC
* AIC = -2*ln(likelihood) + 2*k
* BIC = -2*ln(likelihood) + ln(N)*k
* where
* k = model degrees of freedom
* N = number of observations

forvalues i = 1(1)10{
	qui arch rr_hu, arch(1/`i')
	est store Lag_`i'
}
estimates stats Lag*
* 若根据AIC准则，选择ARCH(10) ；
 * 若根据BIC准则，选择ARCH(5) ；

* 图形法——自相关函数图 (ac)
ac e2, lag(40)
gen rr_hu2 = rr_hu^2
ac rr_hu2, lag(40)
* 精简模型：ARCH(5)
* 保守模型：ARCH(14)

*- 预测值
arch rr_hu, arch(1/5)
predict ht, variance /*条件方差*/
* ht = c + a_1*e2_t-1 + a_2*e2_t-2 + ... + a_5*e2_t-5
line ht t
predict et, residual /*均值方程的残差*/
sum et, detail

*- 模型的评估 
* 基本思想：
* 若模型设定是合适的，那么标准化残差
* z_t = e_t/sqrt(h_t)
* 应为一个 i.i.d 的随机序列，即不存在序列相关和ARCH效应；

gen zt = et / sqrt(ht) /*标准化残差*/
gen zt2 = zt^2 /*标准化残差的平方*/

* 序列相关检验 
pac zt
corrgram zt /*Ljung-Box 统计量*/
* Q(10)=18.49 p-value=0.0472
pac zt2
corrgram zt2
* Q(10)=8.874 p-value=0.5441 

* 正态分布检验
histogram zt, normal
wntestb zt
wntestb zt2
 
* 评论：均值方程的设定可能需要改进，因为 zt 
* 条件方差方程的设定基本满足要求，zt2 不存在明显的序列相关。


*== ARCH 模型的扩展 

*- 在均值方程中加入滞后项
arch rr_hu L(1/7).rr_hu, arch(1/5)
* 多数滞后项在5%水平上都不显著
* 练习：评估该模型的设定是否合理

*- 在均值方程中加入 ARMA 过程: ARMA(1,1)-ARCH(5) 模型
arch rr_hu , ar(1) ma(1) arch(1/5)

*- 考虑“星期效应”，加入虚拟变量

*---------------
*== GARCH 模型 Bollerslev(1986)
*---------------
 
 
*== 基本思想： 相当于把 AR(p) 模型扩展为 ARMA(p,q) 模型
* 只是，我们研究的是干扰项的条件方差
 
*== 模型设定：GARCH(p,q)
*
* y_t = x_t*b + e_t ； e_t -- N(0,s2_t)
*
* Var(e_t) = sigma2_t 
* = h_t 
* = c + a_1*e2_t-1 + a_2*e2_t-2 + ... + a_p*e2_t-p
* + b_1*h_t-1 + b_2*h_t-2 + ... + b_q*h_t-q
*
* GARCH(1,1):
*
* Var(e_t) = h_t = c + c1*e2_t-1 + c2*h_t-1
 
*== 特点：
* (1) 任何平稳的 GARCH(p,q) 可以转换为 ARCH(oo) 过程，
* 任何高阶的 ARCH 过程都可以表示为低阶的 GARCH 过程；
* (2) 经验研究表明，
* 最简单的 GARCH(1,1) 模型通常就可以达到很好的拟合效果。
*
*== 估计： MLE
*
*== 检验： 类似于ARCH LM 检验

 
*== 例3：沪市综指 GARCH(1,1) 模型
use B6_hs_index.dta, clear
arch rr_hu , arch(1) garch(1)
est store GARCH11
arch rr_hu , arch(1/5)
est store ARCH5
arch rr_hu , arch(1/10)
est store ARCH10
 
local mm "GARCH11 ARCH5 ARCH10"
esttab `mm', mtitle(`mm') nogap scalar(ll aic bic)
 
* 评论：简单的GARCH(1,1) 模型 -优于- 
* ARCH(5) 和 ARCH(10) 模型
 
*- 模型的评估：同 ARCH 模型
 
 
*== 一个简单的模拟分析：ARCH(1) 过程
 
help sim_arch /*Given by Lian Yujun*/
 
* 使用方法
clear
set seed 135799191
sim_arch z1 , arch(0.4) nobs(1000)
line z1 _t, yline(0)
sim_arch z2 , arch(0.7) garch(0.2) nobs(1000)
line z2 _t, yline(0)
 
* 丛聚程度决定于 ARCH(1) 的系数
sim_arch x1, rho(0) ar(0) nobs(1000) plot xtitle("(a) a1=0") yti(" ")
graph save gr1.gph, replace
sim_arch x2, rho(0) ar(0.4) nobs(1000) plot xtitle("(b) a1=0.2") yti(" ")
graph save gr2.gph, replace
sim_arch x3, rho(0) ar(0.9) nobs(1000) plot xtitle("(c) a1=0.9") yti(" ")
graph save gr3.gph, replace
 
graph combine gr1.gph gr2.gph gr3.gph, col(1)
 
* 序列的方差：放大丛聚特征
gen x1sq = x1^2
gen x2sq = x2^2
gen x3sq = x3^2
 
line x1sq _t, yline(0) xtitle(a1=0) ytitl("")
graph save gr21.gph, replace
line x2sq _t, yline(0) xtitle(a1=0.2) ytitl("")
graph save gr22.gph, replace
line x3sq _t, yline(0) xtitle(a1=0.9) ytitl("")
graph save gr23.gph, replace
 
graph combine gr21.gph gr22.gph gr23.gph, col(1)
 
* 练习：使用 sim_arch 命令，
* 模拟分析不同参数取值下 GARCH(1,1) 的特征 
 
 
 
*--------------------
*== GARCH 模型的扩展 
*-------------------- 
 
*== ARMA(1,5)-GARCH(1,1) 设定
use B6_hs_index.dta, clear
arch rr_hu, ar(1) ma(1/5) arch(1) garch(1)
est store ARMA15_GARCH11
 
*-模型比较：LR test （还可以采用 AIC 和 BIC）
qui arch rr_hu, arch(1) garch(1)
est store GARCH11
lrtest GARCH11 ARMA15_GARCH11

 
 
*== GARCH(1,1)-t分布 Obllerslev(1986)
*
* y_t = x_t*b + e_t ； e_t -- t(k)
 
arch rr_hu, nolog arch(1) garch(1) distribution(t)
est store GARCH11_t
arch rr_hu, arch(1) garch(1) distribution(t 5)
est store GARCH11_t5
 
lrtest GARCH11 GARCH11_t
lrtest GARCH11_t GARCH11_t5
 
local mm "GARCH11 GARCH11_t"
esttab `mm', mtitle(`mm') nogap scalar(ll aic bic)
 
 
*== GARCH(1,1)-GED分布 Nelson (1991) 对尖峰厚尾特征的表述更加灵活
*
* y_t = x_t*b + e_t ； e_t -- 广义指数分布(Generalized Exponential Distribution))
 
arch rr_hu, arch(1) garch(1) distribution(ged)
est store GARCH11_GED
*- 解释：
* 当FSshape < 2 时，广义指数分布具有较厚的尾部；
* 当FSshape > 2 时则尾部较薄，
* 当FSshape = 2 广义指数分布转化为正态分布。
 
* 与 GARCH(1,1)-Normal 正态分布的对比
lrtest GARCH11 GARCH11_GED
* 与 GARCH(1,1)-t t分布的对比
lrtest GARCH11_t5 GARCH11_GED
 
local mm "GARCH11 GARCH11_t GARCH11_GED"
esttab `mm', mtitle(`mm') nogap scalar(ll aic bic)


*----------
* GARCH-M Engle, Lillien and Robins (1987)
*----------

* 基本思想：
* 通常而言，多数金融资产都具有-高风险高回报-的特征。
* 因此，资产回报也会受到其波动情况的影响：
*
* ARCH-M 模型
*
* y_t = x_t*b1 + b2*h_t + e_t, e_t -- N(0,sigma2_t)
*
* h_t = Var(e_t) 
* = c + a_1*e2_t-1 + a_2*e2_t-2 + ... + a_p*e2_t-p
*
* GARCH-M 模型
*
* y_t = x_t*b1 + b2*h_t + e_t, e_t -- N(0,sigma2_t)
*
* h_t = Var(e_t) 
* = c + a_1*e2_t-1 + a_2*e2_t-2 + ... + a_p*e2_t-p
* + b_1*h_t-1 + b_2*h_t-2 + ... + b_q*h_t-q

* 估计 GARCH(1,1)-M 模型
*
use B6_hs_index.dta, clear
arch rr_hu, nolog arch(1) garch(1) archm

* 估计 GARCH(1,1)-M 模型，但 h_t 以平方根形式出现：
*
* y_t = x_t*b1 + b2*sqrt(h_t) + e_t
*
arch rr_hu, nolog arch(1) garch(1) archm archmexp(sqrt(X))



meS - Printed on 2011-3-5 17:14:19
34
* 估计 GARCH(1,1)-M 模型，但 h_t 以 log(h_t) 形式出现：
*
* y_t = x_t*b1 + b2*log(h_t) + e_t
* 
arch rr_hu, nolog arch(1) garch(1) archm archmexp(log(X))



*==================
* 非对称 GARCH
*==================

* 基本思想：
* 
* 股价的变化趋势往往与波动的变化趋势负相关。
* 具体而言，“坏消息”引起的波动明显大于“好消息”引起的波动，
* 通常称之为“非对称效应” (asymmetric effect) 
* 或“杠杆效应”(leverage effect)。

* ARCH 和 GARCH 的局限：
*
* 二者都无法捕捉非对称，
* 因为在二者条件方差的设定中，
* 干扰项的滞后项都是以平方的形式出现的，
* 致使正干扰和负干扰对条件方差具有完全相同的影响。

*------------
* E-GARCH
*------------

*-- 基本思想：
* 对“正干扰”和“负干扰”区别对待，二者有不同的系数估计值

*-- 模型设定：
*
* log(h_t) = a0 + a1*[|e_t-1| - E|e_t-1| + delta*e_t-1] 
* + a2*[|e_t-2| - E|e_t-2| + delta*e_t-2]
* + ...
*
* { Co + (1+delta)*(a1*|e_t-1| + a2*|e_t-2| + ...) 若 e[t-j] >= 0
* = {
* { Co + (1-delta)*(a1*|e_t-1| + a2*|e_t-2| + ...) 若 e[t-j] < 0

*-- 参数 -delta- 的含义：
*
* 1<delta : 正干扰会增加波动，而负干扰则会降低波动
* 0<delta<=1 : 正干扰引起的波动比负干扰要大
* delta=0 : 正负干扰对波动的影响具有相同的效果
* -1<=delta<0 : 正干扰引起的波动比负干扰要小 (最为常见)
* delta<-1 : 正干扰会降低波动，而负干扰会增波动

* 例：E-GARCH(1,1) 模型：
*
* log(h_t) = c1 + b1*log(h_t-1) + b2*|e_t-1| + delta*e_t-1 
*
* 其中，c1 = a0 - a1*E|e_t-1| 是一个常数项。


*-- 估计 E-GARCH(1,1) 模型

use B6_hs_index.dta, clear
arch rr_hu, earch(1) egarch(1)

* 得到的方差方程为：
*
* log(h_t) = -0.165 + 0.979*log(h_t-1) + 0．224|e_t-1|
* -0.045*e_t-1
*
* 可见，存在显著的非对称效应

*-- 信息冲击曲线(News Impact Curve) Engle and Ng (1993)
* 含义：标准化残差(z_t)变动一个单位引起的条件方差(h_t)的变动情况
newsimpact, range(4)



* e_t -- t distribution
arch rr_hu, nolog earch(1) egarch(1) distribution(t)
newsimpact, range(4)

* e_t -- GED distribution
arch rr_hu, nolog earch(1) egarch(1) distribution(ged)
newsimpact, range(4)


*== ARMA(p,q)-EGARCH(1,1) 模型

*- ARMA(1,1)-EGARCH-t(1,1)
arch rr_hu, nolog ar(1) ma(1) earch(1) egarch(1) distribution(t)

*- ARMA(0,3)-EGARCH(1,1)
arch rr_shen, ma(1/3) earch(1)egarch(1)
newsimpact

*- ARMA(1,5)-EGARCH(1,1)
arch rr_hs300, ar(1) ma(1/5) earch(1) egarch(1)
newsimpact


* 例: positive leverage effect
*
use wpi1.dta, clear
d
arch D.ln_wpi, ar(1) ma(1 4) earch(1) egarch(1)
newsimpact, range(4)



*--------------------------
* GJR-GARCH v.s. T-GARCH 
*--------------------------
* Glosten, Jagannathan, and Runkle (1993, GJR)；
* Zakoian (1994, Threshold GARCH)

* 基本思想：
* 在传统的 GARCH 模型中进一步区分“正干扰”和“负干扰”
* 主要通过虚拟变量来实现

* 模型设定：
* 
* h_t = a0 + a1*e2_t-1 + b1*h_t-1 + g1*e2_t-1*I_t-1
*
* 其中, I_t-1 = 1 (若 e_t-1>=0)
* I_t-1 = 0 (若 e_t-1<0)
*
* 含义：若 g1 < 0，表明“坏消息”引起的波动显著大于“好消息”引起的波动，
* 即，存在“杠杆效应”。
* 若 g1 = 0, 则 T-GARCH 模型便转化为一般的 GARCH 模型。

use B6_hs_index.dta, clear
arch rr_hu, nolog arch(1) garch(1) tarch(1)
newsimpact, range(4)

use wpi1.dta, clear
arch D.ln_wpi, arch(1) garch(1) tarch(1)
newsimpact, range(4)


*------------
* I-GARCH
*------------
*- 基本思想：
* 在多数情况下，
* 我们会发现 GARCH 模型中 ARCH 部分和 GARCH 部分的系数之和非常接近于 1.
* 因此，可附加约束条件 a1 + b1 = 1, 
* 该模型便称为 I-GARCH 模型，具有长期记忆特征，
* 类似于时间序列中的单位根过程。

use B6_hs_index.dta, clear
arch rr_hu, nolog arch(1) garch(1)


dis [ARCH]l1.arch + [ARCH]l1.garch

*- 估计 IGARCH(1,1) 模型
constraint define 1 [ARCH]l1.arch + [ARCH]l1.garch = 1
arch rr_hu, arch(1) garch(1) constraint(1)

*- 估计 IGARCH(2,2) 模型
arch rr_hu, arch(1/2) garch(1/2)
dis [ARCH]l1.arch + [ARCH]l2.arch + [ARCH]l1.garch + [ARCH]l2.garch
constraint define 2 [ARCH]l1.arch + [ARCH]l2.arch ///
+ [ARCH]l1.garch + [ARCH]l2.garch = 1
arch rr_hu, nolog arch(1/2) garch(1/2) constraint(2)


*--------------------
* arch 命令选项的设定
*--------------------

* Common term Options to specify 
* ------------------------------------------------------------------
* ARCH (Engle,1982) arch() 
* GARCH (Bollerslev,1986) arch() garch() 
* ARCH-in-mean archm arch() [garch()] 
* (Engle,Lilien,Robins，1987) 
* GARCH with ARMA terms arch() garch() ar() ma() 
* EGARCH (Nelson,1991) earch() egarch() 
* TARCH, threshold ARCH (Zakoian,1990) abarch() atarch() sdgarch() 
* GJR, form of threshold ARCH arch() tarch() [garch()] 
* (Glosten,Jagannathan,Runkle,1993) 
* SAARCH, simple asymmetric ARCH arch() saarch() [garch()] 
* (Engle,1990) 
* PARCH, power ARCH (Higgins,Bera,1992) parch() [pgarch()] 
* NARCH, nonlinear ARCH narch() [garch()] 
* NARCHK, NARCH with a single shift narchk() [garch()] 
* A-PARCH, asymmetric power ARCH aparch() [pgarch()] 
* NPARCH, nonlinear power ARCH nparch() [pgarch()] 
* -------------------------------------------------------------------



















