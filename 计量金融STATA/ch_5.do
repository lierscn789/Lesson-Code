cd C:\Users\yecha\Documents\金融计量

*VAR模型：向量自回归模型
*VAR模型是用模型中所有当期变量对所有变量的若干滞后变量进行回归。VAR模型用来估计联合内生变量的动态关系，而不带有任何事先约束条件。它是AR模型的推广，此模型目前已得到广泛应用。

*Y_T=C+A_1*Y_T-1+...+A_P*Y_T-P+B*X_T+U_T
// 假设：
// E(U_T)=0
// E(U_T*U_T')=S 各干扰项之间存在同期相关性，干扰项也是一个向量，因此同一期内得干扰项之间可以存在相关性
// E(U_T*U_s')=0 各个干扰项之间不存在跨期相关性

*估计VAR
*选择滞后阶数
use lutkepohl.dta ,clear 
tsset qtr
d
varsoc dlinvest dlincome dlconsumption, maxlag(4)
*soc表示selection-order criteria , maxlag 表示最大滞后期
*报告AIC BIC准则以及似然估计，根据两个准则选出其中最小的，例如2阶最小则选2阶

*估计模型：便捷命令 varbasic
varbasic dlinvest dlincome dlconsumption , lag(1/2) nograph //不画脉冲响应图
*lag(1/2)表示滞后1-2阶
*结果表示了任何一个变量关于所有变量包含所有滞后期的线性模型，例如哪一个和哪一个的第几期有显著相关
est store varbasic
*varbasic dlinvest dlincome dlconsumption , lag(1/2) irf //画出未正交化的脉冲响应图
*varbasic dlinvest dlincome dlconsumption , lag(1/2) oirf //画出正交化的脉冲响应图

*等价于估计联立方程组模型,表示三个模型之间有关系
* reg3表示three-stage least squares (3SLS)
*reg3一般用来做截面或时间序列的联立方程估计
reg3 (dlinv L(1/2).dlinv L(1/2).dlinco L(1/2).dlconsu) ///
(dlinco L(1/2).dlinv L(1/2).dlinco L(1/2).dlconsu) ///
(dlcons L(1/2).dlinv L(1/2).dlinco L(1/2).dlconsu)
est store reg3

*换了一下顺序没差
// reg3 (dlinv L(1/2).dlinv L(1/2).dlinco L(1/2).dlconsu) ///
// (dlinco  L(1/2).dlinco L(1/2).dlinv L(1/2).dlconsu) ///
// (dlcons L(1/2).dlconsu L(1/2).dlinv L(1/2).dlinco )

*估计VAR的正式命令
var dlinvest dlincome dlconsumption,lag(1/2)
est store var 

esttab reg3 var*
*脉冲响应模型，脉冲变量的外部冲击对于内生变量即相应变量的影响，并且基本上随着滞后期的增加影响越来越弱

*脉冲响应图形(未正交化)
varbasic dlinvest dlincome dlconsumption, irf

irf graph irf, lstep(1) //未正交化，且从1期开始
irf graph oirf , ; lstep(1) //正交化的

*F值 t统计量

var dlinvest dlinco dlcons, lag(1/2) small //小样本下的自由度的调整，报告t值，大样本霞报告的是z值，wald检验
*默认设定下，在估计方差-协方差矩阵时，采用大样本下的1/T进行自由度调整	
*使用dfk选项后，采用1/T-M调整自由度
var dlinvest dlinco dlcons,dfk
est store var_dfk //多数t值变小了，即标准误变大了
esttab var var_dfk,mtitle(var var_dfk)

*包含外省变量的VAR模型
*假设消费是外生的

var dlinvest dlincome ,exog(dlconsu) lag(1/2) small 

*Blanchard模型
*y GDP.u-失业率 p-物价指数 w-工资 m-货币供给 s1-s3季节虚拟变量
use Blanchard.dta, clear 
tsset quarter 
d 
var d.y u d.p d.w d.m, exog(t s1 s2 s3) lags(1 2 3)

*var模型相关检验

use lutkepohl.dta , clear 
var dlinvest dlincome dlconsu, lag(1/2) dfk small 
est store var0
*平稳性检验
varstable //显示3x2个特征根，所有特征根在单位圆内，说明VAR模型时平稳的
varstable, graph //图示模的分布
varstable, graph dlable
varstable, graph modlable


varwle //估计 VAR后，对每个方程以及所有方程的个阶系数的联合显著性进行WALD检验 wle表示 wald lag-exclusion statistics
*结果发现dlinvest dlincome只有一阶滞后方程显著相关，
*处理方法：附加约束条件

constraint define 1 [dlinvestment]L2.dlinvestment = 0
constraint define 2 [dlinvestment]L2.dlincome = 0
constraint define 3 [dlinvestment]L2.dlconsumption = 0
constraint define 4 [dlincome]L2.dlinvestment = 0
constraint define 5 [dlincome]L2.dlincome = 0
constraint define 6 [dlincome]L2.dlconsumption = 0
var dlinvest dlincome dlconsumption , lag(1/2) dfk small constraints(1/6)
est store varC

esttab var0 varC,mtitle(var0 varC) scalar(ll aic hqic sbic)
eret list

//残差正态分布检验
var dlinvest dlincome dlconsumption if qtr<=q(1978q4),lag(1/2) dfk small
varnorm //三哥统计量均无法拒绝残差服从正态分布的原假设分别是Jarque-Berta检验，偏度峰度检验

var dlinvest dlincome dlconsumption,lag(1/2) dfk small
varnorm 


*残差序列相关检验
varlmar //拉格朗乘数检验,原假设是不存在序列相关性
varlmar, mlag(5) //指定最大滞后阶数


*预测
var dlinvest dlincome dlconsumption,lag(1/2) dfk small

varfcast compute 
*样本外一步预测one step
*y_f预测值 y_f_L预测下限 y_f_U预测值上限 y_f_se 预测标准误
list dlinvestment dlinvestment_f dlinvestment_f_L ///
dlinvestment_f_U dlinvestment_f_se in 91/93


*样本内一步预测：dynamic()选项

var dlinvest dlincome dlconsumption,lag(1/2) dfk small
varfcast compute, dynamic(5) //表示第五期开始预测一期
list dlinvestment dlinvestment_f dlincome dlincome_F ///
dlconsumption dlconsumption_f in 4/7

*多步预测：dynamic()选项 +step()选项
varfcast compute ,dynamic(85) step(10)
lsit dlinvestment dlinvestment_f dlincome dlincome_F ///
dlconsumption dlconsumption_f in 83/95

*脉冲响应
*系统外冲击
use lutkepohl.dta , clear 
var dlinvest dlincome dlconsumption,lag(1/2) dfk small //dfk对自由度进行调整，由于样本较小，提高模型标准差的估计
*创建一个IRF脉冲的文件
irf create order1, set(myirf1) step(10) replace //step表示考察截止#期的脉冲响应函数，默认为step(8)
* irf create irfname , set(filename ) step(#) replace order(varlist)
* order指定变量排序，默认使用估计VAR时的变量排序计算正交化IRF

*画图

irf graph oirf, impulse(dlincome) response(dlconsumption) irf(order1)
*画正交化的脉冲响应图，oirf分解与变量的顺序有关，impulse表示脉冲变量，response表示响应变量，最后的图横坐标表示滞后阶数1-10阶。可以看到大于3阶后，影响接近于0
*非正交化的响应图，则把o去掉，变成irf graph irf 正交的英文为Orthogonal
*VAR模型把所有变量当做内生变量
*上述图把dlconsumption的变化分成了相互正交的来自另外两个变量的影响
*如果运行的是irf graph oirf, irf(order1)则表示每两个变量分别作为冲击变量都进行一次，所以总共9x2个图


* 看一下dlincome的预测误差分解 focast error variance decomposition
irf table fevd, r(dlincome) noci //noci不显示置信区间 r()为相应变量
*显示了最近的脉冲模型order1中响应变量是dlincome的所有模型，冲击变量为所有变量，包括本身因此共三个，每个模型共10期

*其中的数值表示模型中能够由该冲击变量解释的error百分比
*因此三个值加起来要等于1

*改变变量顺序以后对比，稍微有点差别
irf create order2, step(10) order(dlincome dlinvest dlconsumption) replace
irf graph oirf, irf(order1 order2) impulse(dlincome) response(dlconsumption)
irf graph coirf, irf(order1 order2) impulse(dlincome) response(dlconsumption) //coirf表示累计正交响应




















