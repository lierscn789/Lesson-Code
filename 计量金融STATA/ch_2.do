*====================================
*------------ 课堂案例----
*====================================

*---逐步回归方法的应用———汽车价格影响因素的分析
cd C:\Users\yecha\Documents\金融计量
sysuse auto,clear
browse


*将自变量一次纳入回归模型，将其中p>置信度例如0.05的变量去除以后再进行一次回归再重复直到所有变量的p都符合条件
stepwise, pr(0.05): reg price length mpg weight displ foreign  //逐个剔除

*逐个分层剔除从最后一个变量开始，如果最后一个变量显著则停止，如果不显著则剔除。因此前面的变量不一定线性显著
stepwise, pr(0.05) hier: reg price length mpg weight displ foreign //逐个分层剔除

    * pr(#)             significance level for removal from the model
    * pe(#)             significance level for addition to the model

*逐个加入变量，选择p值最大的的先加入，以此类推，按照p值由大到小加入符合条件的'
stepwise, pe(0.05): reg price length mpg weight displ foreign //逐个加入
stepwise, pe(0.05) hier: reg price length mpg weight displ foreign //逐个分层加入

*----t检验、F检验———
import excel using production.xlsx, first clear
browse
* 单变量检验
    *use B1_production.dta,clear
reg lnY lnL lnK

* Test linear hypotheses after estimation

test lnL = 0 //检验线性回归模型，p=0.0001拒绝原假设
test lnL = 0.7
  
  test (lnL=0)  (lnK=0) //联合检验
  
  
  * 线性约束检验
    reg lnY lnL lnK
	*lincom用于计算线性模型点估计，标准差，t/z统计量，p值，置信区间，例如加上or选项表示输出优势比
     lincom lnL + lnK //假设是lnL + lnK=0 ，p值很小，拒绝原假设
     lincom lnL + lnK - 1 //假设lnL + lnK =1
	 lincom lnL ,or //表示lnL=0对于lnL不为0的优势比
  
 
  //te: 非常好用，返回t值
  * 包含线性约束的估计，在限制条件的基础上进行线性拟合
     constraint define 1 lnL+lnK = 1 //没有define也可以
     cnsreg lnY lnL lnK, constraints(1)  // constrained linear regression 
	 
    preserve //preserve and restore data 使得程序结束以后保存下来\
*这里的数据后面还要继续用，
	
	
    sysuse auto,clear
     constraint def 1  displ = weight
     constraint def 2  gear_ratio = -foreign
    cnsreg price mpg  weight displ gear_ratio foreign length, c(1-2)
    restore
  * 联合检验
  
  
    reg lnY lnL lnK
    test lnL lnK
    test (lnL=0.8) (lnK=0.2)
   * 模型的整体拟合程度
   * F 检验：检验除常数项外其他所有解释变量的联合解释能力是否显著
   * X= [X1 X2]   X1=常数 | X2=lnL lnK
    test lnL lnK
    reg lnY lnL lnK
  * 非线性约束检验
    testnl _b[lnL] * _b[lnK] = 0.25  //_b[coef] coef为变量名 _b[eqno:coef] eqno为
    testnl _b[lnL] * _b[lnK] = 0.5


 *------自相关检验:德宾-沃森检验(Durbin-Watson Test)-------
    preserve
     sysuse auto,clear
  drop in -4/-1
     lmadw price length mpg , lags(3)  //
    restore
 
*---------残差检验---------------- 
 sysuse auto, clear 
 
*利用Jarque-Bera检验检验一个数据的偏度和峰度是否一个正态分布
    lmnjb price length mpg foreign
 
 
 reg price length mpg foreign
 predict yhat //利用回归的线性方程预测price（y值），并且newvar命名为yhat
 
 
    predict e, res //res表示residuals ，这个option用于得出残差。e为newvar的名字
 qnorm  e  // QQ图，查看残差是否符合正态分布
 kdensity e, normal //查看正态分布与残差分布关系
 
 
 
*----回归模型的结构稳定性检验-------
   sysuse auto, clear 
   br
*--(1)变截距

*图示  
sysuse auto, clear //初始化数据

drop if weight<3000&foreign==0
*虚拟变量即定性变量，包括指标变量，二元变量，分类变量
*twoway用于画twoway的图，多个括号表示画在一起
*lw是lwidth缩写，lp是lpattern的缩写，包括solid dashed... 
*msymbol表示shape of marker，例如circle记为O,diamond_hollow缩写dh,其实就是空心的菱形
twoway (scatter price weight if foreign==0,yscale(range(0 14000)))  ///scatter表示散点图
       (lfit price weight if foreign==0,lw(medthick))               ///lfit表示线性预测模型
       (scatter price weight if foreign==1,msymbol(dh))             ///
       (lfit price weight if foreign==1,lw(medthick))               ///
       (lfit price weight,lw(thick) lp(longdash)),                  ///
       ytitle(汽车价格)                                             ///
       legend(label(1 "国产车") label(2 "国产拟合") label(3 "进口车") ///
              label(4 "进口拟合") label(5 "整体拟合") rows(2))
     
     
* 检验方法     
 reg price weight
 reg price weight if foreign==0
 reg price weight if foreign==1

 gen dum = 0 //生成的变量都是对整个变量而言，因此这一步生成了一列名为dum全为0的变量，之前use 的是哪一个数据就对哪一个数据操作
 replace dum = 1 if foreign==1 //这是对变量进行了操作

 reg price dum weight //回归结果中dum的系数表示因为进口因素对价格的影响程度（额外增加的价格，即对常数项的影响）
 * model: price = a0 + a1*dum + b*weight + u 
   * price = a0      + b*weight + u  /*dum=0 国产车*/
   * price = (a0+a1) + b*weight + u  /*dum=1 进口车*/
  




*--(2)斜率和截距同时变

*图示 
sysuse auto, clear

twoway (scatter price weight if foreign==0,yscale(range(0 14000)))  ///
       (lfit price weight if foreign==0,lw(medthick))               ///
       (scatter price weight if foreign==1,msymbol(dh))             ///
       (lfit price weight if foreign==1,lw(medthick))               ///
       (lfit price weight,lw(thick) lp(longdash)),                  ///
       ytitle(汽车价格) ///
       legend(label(1 "国产车") label(2 "国产拟合") label(3 "进口车") ///
              label(4 "进口拟合") label(5 "整体拟合") rows(2)) 
     
* 检验方法
     
gen dum = foreign==1
gen dum_weight = dum*weight
*这个模型认为进口车不仅对于常数项有额外影响，还会增加weight对于price的影响权重

reg price dum weight dum_weight
* model：price = a0 + a1*dum + b0*weight + b1*dum_weight + u
  * price = a0      +  b0*weight     + u   /*dum=0 国产车*/
  * price = (a0+a1) + (b0+b1)*weight + u   /*dum=1 进口车*/
reg price weight


  
*--(3)交乘项
* y = b0+ b1*x1 + b2*x2 + b3(x2*x3)
* dy/dx2 = b2 + b3*x3   i.e., x2 的边际效果依赖于 x3
sysuse auto, clear
gen weiXlen = weight*length //增加length对结果的关键性作用
reg price weight mpg foreign weiXlen
* 汽车越长，重量对价格的边际影响就越小 



*--(4)结构突变检验：Chow test
 
*图示 
  sysuse auto, clear
  *drop if price>13000
  twoway (scatter price wei if foreign==0,msymbol(T))  ///
         (lfit price weight if foreign==0)  ///
         (scatter price wei if foreign==1)  ///
         (lfit price wei if foreign==1), ///
         yscale(r(1000 14000))  ///
         legend(label(1 "国产") label(3 "进口")) 
   
   
* 检验方法
    gen foreign_wei = foreign*weight
    gen foreign_len = foreign*length
    reg price wei len foreign foreign_wei foreign_len
    * 模型的含义
    *  price = c1 + a1*wei + b1*len + c2*foreign + a2*foreign_wei + b2*foreign_len
    *  price =  c1     +  a1*wei     +  b1*len      /*foreign==0*/ 
    *  price = (c1+c2) + (a1+a2)*wei + (b1+b2)*len  /*foreign==1*/ 
   test foreign foreign_wei foreign_len    /* c2=0; a2=0; b2=0 */   
//test后跟几个变量名 检验假设为所列的相关系数为0
   
   
*--(5)结构突变检验：虚拟变量法   
   
 sysuse auto, clear 
 gen D= foreign==0
 gen D_length=D*length
 reg price D length D_length 