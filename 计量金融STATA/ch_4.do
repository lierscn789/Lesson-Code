cd C:\Users\yecha\Documents\金融计量
/*1、泰坦尼克号“妇女儿童优先”政策*/
use titanic.dta, clear
browse //浏览有哪些数据，并且输出频数

summarize survive if class3==1 & (child==1| female ==1) [fweight =freq]

summarize survive if class1==1 & child ==0 & female ==0 [fweight =freq]
logit survive child female class* [fweight =freq],r nolog //class1系数为正显著说明class1的船员优先得救，class3系数为负说明显著落后得救
logit survive child female class* [fweight =freq],or r nolog //报告胜算比，说明儿童存活的优势比是2.9，女性存活率是男性的11倍




drop group
gen group="wc" if (female==1& class3==1 )|(child ==1 & class3==1)
replace group="m1" if female==0 & child ==0 & class1 ==1
keep if group != ""
ttest survive, by(group)

/*
gen n = _n
*将汇总数据按照freq扩大成个例数据
expandcl freq, generate(newcl) cluster(n)
drop n freq newcl
*将妇女儿童归为一类，fc=1表示是妇女儿童
gen fc=1
replace fc=0 if child==0 & female==0
*构造逻辑回归模型
logit survive class* fc
logit survive class* fc, or
*将一等舱男归为一类，记为man1，三等舱妇女儿童归为一类，记为fc3，其他人记为other
gen man1=0
replace man1=1 if fc==0 & class1==1
gen fc3=0
replace fc3=1 if fc==1 & class3==1
gen others=0
replace others=1 if man1==0 & fc3==0
*构造逻辑回归模型，观察fc3的系数
logit survive fc3 others, or
*/

use loanapp.dta, clear
logit approve white, r

local xx "hrat obrat loanprc unem male married dep sch cosign chist pubrec mortlat1 mortlat2 vr"
logit approve white  `xx' ,r
est store lr
probit approve white  `xx' ,r
est store pr
esttab lr pr,mtitle("lr")
logit approve white  `xx' ,r or //输出优势比



*------------------------------
          *            4.1  ARIMA 模型
                  
cd C:\Users\yecha\Documents\金融计量\ch4_data


*=======================
*   平稳时间序列模型     
*=======================

*-----------------
*   ARIMA 模型       help arima
*-----------------
*-- AR 过程与 MA 过程
*-- 自相关系数与偏自相关系数
*-- 滞后阶数的筛选
*-- 估计
*-- 预测


* -- 简介 --

*一、AR 过程(自回归过程)
  * AR(1): y_t = rho*y_{t-1} + u_t 
  * AR(p): y_t = r_1*y_{t-1} + r_2*y_{t-2} + ... + r_p*y_{t-p} + u_t

  clear
  help sim_arma
  
  sim_arma y_ar, ar(0.9) nobs(300)
  
  line y_ar _t, yline(0)
  br
  *-----------------------------------------------------------
  * 自相关系数(ACF)
  *                 Cov[y_t, y_{t+s}]
  *          r_s = -------------------
  *                      Var[y_t]  
  * 偏自相关系数(PACF)
  *   y_t = a11*y_{t-1} + u_t
  *   y_t = a21*y_{t-1} + a22*y_{t-2} + u_t
  *     ...
  *   y_t = ak1*y_{t-1} + ak2*y_{t-2} + ... + akk*y_{t-k} + u_t
  *
  * PACF 为 {a11, a22, a33, ... , akk}
  * 相当于控制其它滞后项的影响后，得到的“净”相关系数
  *-----------------------------------------------------------  
  
  
  ac  y_ar    /*AR过程的  ACF 具有“拖尾”特征，长期记忆*/  
  pac y_ar    /*AR过程的 PACF 具有“截尾”特征*/
  
  * 评论：根据AC和PAC图形可以初步判断某个序列是否为AR过程
  *       具体表现为：
  *       (1) AC  图“拖尾” (长记忆性) 
  *       (2) PAC 图“截断”(截断处对应的阶数就是AR的滞后阶数P)
  
 
*1. 阶数的判定:
   *方法一: PAC图法
   *方法二: 信息准则法
     * LL值，AIC准则，BIC准则
     * LL 越大越好, AIC 和 BIC 越小越好
     *  AIC = -2*ln(L) + 2*k      /*ln(L) 对数似然值；k 参数个数； N 样本数*/
     *  BIC = -2*ln(L) + k*ln(N)
     *  BIC 更倾向于筛选出“精简的”模型
 
    * 采用信息准则筛选滞后阶数
        
        *局部暂元
        
     local y "y_ar"
     local a = 3   /*AR(a)*/
     forvalues i = 1(1)`a'{
               quiet arima `y' , ar(1/`i')  /*填写变量名称*/
               est store ar`i'
               qui estat ic
     }
     local mm ar1 ar2 ar3
   esttab `mm', mtitle(`mm') compress nogap scalar(ll aic bic) 
 
    help esttab
 
*2.估计

 arima y_ar, ar(1)
 
*3.检验：检验白噪声 (本质上是序列相关性检验) ---  wntestq
 * wntestq  (Ljung-Box Q test for white noise, Ljung-Box Q, 1978) 
predict e, r
wntestq e   //使用stata默认滞后期
wntestq e, lags(10) //自己指定滞后期


*4. 预测:
 
 *-(1).样本内预测                 /* y 的拟合值 */
 
    arima y_ar, ar(1)

    predict y_hat 

 *-(2). 样本外预测

    list  y_ar y_hat in -15/-1
    tsappend, add(2)  //追加2个观测值
    predict y_hat1     /* y 的样本外一步预测值 */
    list y_ar y_hat y_hat1 in -15/-1

  
   *(3) 动态预测
    predict y_hat_d, dynamic(294)  /*动态预测*/
        list y_ar y_hat y_hat1 y_hat_d  in -15/-1
        
    * 解释：
    *   当 t<=294 时，采用 y_t 的真实值进行预测；
    *   当 t>294 时，采用 y_t 的预测值进行进一步的预测


*白噪声过程
*y_t=e_T e_T服从IID(0,1)

clear
set obs 100
gen y1=invnorm(uniform()) //uniform在0,1之间均匀分布，invnorm为正态分布的累积分布函数
gen t=_n
tsset t
line y1 t , yline(0)
*检验白噪声
*Ljung-Box Q检验
wntestq y1 //使用stata默认滞后期，默认40阶
wntestq y1, lags(20) //无法拒绝原假设

*随机游走过程
*w_t =w_t-1 +e_t 其中w_t=0 ,e_t服从iid(0,1)
*w_t =w_t-2+e_t-1 +e_t
*.....
*w_t=w_0+(e_1+e_2+...+e_t)
*w_t的当期观察值是以往所有干扰因素的累积

clear 
set seed 1234
set obs 300
gen t=_n
tsset t
gen y0=invnorm(uniform()) //产生白噪声过程
sim_arma y1 , ar(0.9) //生成AR(1)过程 yt=0.9y_t-1 +e_t，平稳过程，波动更大一些但依然满足均值回复
sim_arma y2 , ar(1) //RW 随机游走过程 yt=yt-1 +e_t 其中y_t-1继续代入最终得到随机游走过程，这里e_t的方差为1

twoway (line y0 t ) (line y1 t ) (line y2 t ), legend(label(1 "WN") label(2 "AR(0.9)") label(3 "RW") row(1))

capture drop y3 //可以不提示错误保持运行
sim_arma y3, ar(1) sigma(3)
twoway (line y0 t ) (line y1 t ) (line y2 t ) (line y3 t ), legend(label(1 "WN") label(2 "AR(0.9)") label(3 "RW") label(4 "RW3") row(1)) 
//频繁穿越0的为平稳过程


*带有漂移项的随机游走过程

*  y_t =c0+y_t-1 +e_t-1

*y_t=c0+y_t-1_e_t
*...
*y_t=m*c0+y_t-m+sum e_t-e_t-m+1
*漂移项的存在具有累加效果

clear 
set obs 100
gen t=_n
tsset t
gen u=invnorm(uniform()) //白噪声作为e_T项
gen y=0
forvalues i=2(1)100{ //从第二项开始
qui replace y=0.1+y[`i'-1]+u if t==`i'
}


*含有时间趋势项的平稳序列
gen x=0.1*t +u
label var y RW_drift
label var x WN_trend
twoway (line y t) (line x t) //两者都是非平稳的，可以看到带有漂移项的上升相对更快，带有时间趋势项的上升因为系数只有0.1所以较慢


tsset t 

*用过简单的回归分析判断随机过程是否含有时间趋势项)

reg y L.y //可以看到回归是显著的，因为本来模型中就存在自相关
est store ylag
reg y t //可以看到t也是显著的，所以要看是否有时间趋势项要固定滞后项
est store yt
reg y L.y t //控制滞后项以后可以看到t不再显著，因此y没有时间趋势项
est store ytlag 

reg x L.x //x是具有滞后项的随机过程
est store xlag
reg x t
est store xt //两个模型下t都是显著的
reg x L.x t 
est store xtlag 

local mm "ylag yt ytlag xlag xt xtlag"
esttab `mm' , mtitle(`mm') compress 


*非平稳序列对估计结果的影响：伪回归问题

*可以看到y(带有漂移项的随机游走过程)和x(带有时间趋势项的平稳)具有高度相关性，但实际上他们是独立的


*一个简单的实例

clear 
set obs 1000
sim_arma y,ar(1)
sim_arma x,ar(1)
reg y x
dwstat //DW统计量=2(1-rho)
twoway line y _t || line x _t

*可以看到两者似乎存在很强的相关性
*两个非平稳序列很容易出现伪回归
*两个平稳序列比较难出现伪回归




*B6_simreg_r
 cap program drop B6_simreg_r
 program define B6_simreg_r, rclass
 version 8
         
         syntax [, obs(integer 1000)]
    
         tempvar x y t e //定义临时变量,作为暂元
         tempname V dw 
         
         gen `t' = _n
         qui tsset `t'
         
         gen `x' = invnorm(uniform())
         gen `y' = invnorm(uniform()) 
         
         reg `y' `x'
         mat `V' = e(V) //输出方差矩阵Variance 
         return scalar b = _b[`x'] //输出系数β
         return scalar t = _b[`x']/sqrt(`V'[1,1]) //计算回归系数β的t统计量
         return scalar r2= e(r2)
         
         predict `e',resid //获得残差
         reg `e' L.`e'
         scalar `dw' = 2*(1-_b[L.`e'])
         return scalar dw = `dw'   
         
end

*B6_simreg_u
//gen two unstationary series and reg
//then calculate b t R2 and D-W values
//The next step is to carry out Mante Carle simulation


cap program drop B6_simreg_u
program define B6_simreg_u, rclass
version 8
      
      syntax [,rho(real 1) obs(int 1000)]
      
      tempvar x1 y1 t e
      tempname V  dw
    
      gen `t' = _n
      qui tsset `t'
     
      sim_arma `y1', ar(`rho')
      sim_arma `x1', ar(`rho') 

      qui reg `y1' `x1'
      mat `V' = e(V)
         return scalar b  = _b[`x1'] //返回系数
         return scalar t  = _b[`x1']/sqrt(`V'[1,1])
         return scalar r2 = e(r2)

         predict `e',resid
         qui reg `e' L.`e'
         scalar `dw' = 2*(1-_b[L.`e'])
         return scalar dw = `dw'
         
end



*模拟分析
*随机产生两个序列y和x
cd C:\Users\yecha\Documents\金融计量\ch4_data


*模拟A ：两个平稳序列 y-N(0,1) ;x-N(0,1)
doedit B6_simreg_r.ado //和运行上面那段程序效果一样

simulate "B6_simreg_r" ///
b_s=r(b) t_s=r(t) r2_s=r(r2) dw_s=r(dw), rep(300) dots //存储所有的返回值，r()表示返回值，dots表示用点来表示
gen id=_n
qui sort id 
save B6_simreg_r.dta ,replace 

*模拟B：两个非平稳序列
//
// doedit B6_simreg_u.ado

simulate "B6_simreg_u" ///
b_u=r(b) t_u=r(t) r2_u=r(r2) dw_u=r(dw), rep(300) dots 
gen id=_n
qui sort id 
merge id using B6_simreg_r.dta //横向合并,merge=3表示完全匹配
drop _merge id 
sum 


*对比分析

*两个独立的非平稳序列可能高度相关：伪回归

*系数的分布，可以发现平稳序列的
twoway (kdensity b_s, lwid(thick)) (kdensity b_u, lwid(thick)) , ///
legend(label(1 "b-稳定序列") label(2 "b_非稳定序列") )

*t检验量稳定序列大部分接近于0无法拒绝原假设，非平稳序列分布较广说明经常出现极端值，拒绝原假设，认为存在线性相关
twoway (kdensity t_s, lwid(thick)) (kdensity t_u, lwid(thick)) , ///
legend(label(1 "t-稳定序列") label(2 "t_非稳定序列") ) 

*R2稳定序列基本很小，费平稳序列存在接近于1的
twoway (kdensity r2_s, lwid(thick)) (kdensity r2_u, lwid(thick)) , ///
legend(label(1 "R2-稳定序列") label(2 "R2_非稳定序列") )

*非平稳序列的DW统计量很小，在0附近，平稳序列的DW统计量较大在2附近，一般当DW统计量大于2可以认为残差之间相互独立
twoway (kdensity dw_s, lwid(thick)) (kdensity dw_u, lwid(thick)) , ///
legend(label(1 "DW-稳定序列") label(2 "DW_非稳定序列") )

*因此当两个时序变量回归得到的R2较高，系数也显著，但DW值接近于0则可能是伪回归
*此时需要检验时序变量的平稳性！，如果是非平稳的很有可能是伪回归所致

*******************************

*单位根检验

*单位根过程(等价于随机游走)

*y_t=y_t-1+e_t (原假设，单位根过程=随机游走过程) e_T --IID(0,sigma^2)
*y_t=c0+y_t-1+e_t  c0为漂移项

*三种检验方法,原假设都一样是随机游走过程，备择假设有三种
*备择假设分别是：
*一阶平稳的自回归AR(1)过程 yt=φy_t-1+e_t (φ<1)就实际情形来说系数都小于1
*带有漂移项的的平稳AR(1)过程yt=c0+φy_t-1+e_t 
*带有漂移项和时间趋势项的平稳AR(1)过程 yt=β1+β2t+ φy_t-1+e_t 
*前面两周情形可以看做第三种情形的特例

*三种检验方法为：DF检验 ADF(augmented放大的)检验  PP检验
*DF检验的统计量DF=ψ / se(ψ) 其中ψ=φ-1



*ADF检验可以看成DF检验的推广,因为DF检验是一种OLS估计可能存在序列相关性，ADF检验不考虑序列相关性

*ADF中原假设为y_t为单位根过程，H1为y_t是平稳序列

*再进行检验之前，需要根据具体的时间序列来做一些选择：是否含有漂移项、时间趋势项
*通过时序图观察，可以判断时间序列的均值是否为零，或是否在非零的平均值附近波动
*观察是否存在线性或者二次趋势，如果存在二次趋势，则它的差分样本将具有线性趋势
*理论上时间趋势项也有二次的，但是实证分析表明一般不用考虑

*检验联邦基金回报率与三年期债券回报率的平稳性
// log using unittest , replace text 

cd C:\Users\yecha\Documents\金融计量\ch4_data
use usa,clear
gen date=q(1984q1)+_n-1
format %tq date
tsset date 


*graph 
qui tsline f,name(f,replace ) //name表示用f命名
qui tsline D.f, name(df,replace ) yline(0) //显示一阶差分
qui tsline b , name(b,replace) //b是三年期国债利率
qui tsline D.b , name(db,replace) yline(0) //一阶差分后是平稳的

graph combine f df b db , cols(2)

*ADF检验有四种形式，原假设都是认为是单位根过程
*ADF检验的H1： D.y_t(差分形式)=a(漂移项)  +b*y_t-1 +deta*t(时间趋势项) +(c1*D.y_t-1+c2*D.y_t-2+...ck*D.y_t-k)(为了控制序列相关,去掉自相关性)
*原假设诸如：是随机游走但是有/没有漂移项 y_t=y_t-1+u_t (+a漂移项)(+delta*t时间趋势)
*----------------------------------
*漂移项即常数项
*四种情形的对应的H0有些诧异但是核心都是关注y_t-1的系数是否为1
*第一种形式RW，无漂移项，dfuller选项为noconstant，无漂移项无趋势项，相当于yt=b*y_t-1
*第二种形式dfuller默认设置，有常数项，但是不关心常数项是否为0，
*第三种形式RW,有漂移项，dufller选drift，此时无趋势项,有漂移项相当于yt=b*y_t-1+a
*第四种包含时间趋势项

*第一种与第二种很类似，原假设都是a=0，但是case2中回归时会加入常数项
*----------------------------------
*关于ADF检验 Schwert建议的最大滞后阶数为12*(T/100)^1/4

regress D.f L.f L.D.f //非平稳，相当于检验上面的等式L.D.f是y_t-1的差分项
regress D.b L.b L.D.b //非平稳

dfuller f ,regress lags(1) //进行检验，regress表示报告出辅助回归的系数
*p不能拒绝原假设，认为是单位根过程，DF统计量即表中的Z统计量，如果该统计量比临界值小的话则拒绝原假设，越小越倾向于拒绝原假设
dfuller b , regress lags(1)

dis 12*(104/100)^(1/4) //查看最大阶数，为12

*做完一阶差分以后
dfuller D.f , noconstant lags(0) //发现Z(t)小于临界值，拒绝原假设，认为差分序列是平稳的(b<1)
dfuller D.b, noconstant lags(0)

*另外一个例子

cd C:\Users\yecha\Documents\金融计量\ch4_data
use lutkepohl.dta, clear 


*第二种形式的DF检验，有常数项(漂移项)，但是不关心是不是为0
dfuller lconsumption //无法拒绝原假设(yt-1的系数为1)，认为是单位根过程，相当于认为系数为1
dfuller lconsumption,regress //显示回归结果

*第二种形式的ADF检验
*不考虑序列相关(前面去掉滞后项的线性影响)时为DF检验，考虑时为ADF检验
dfuller lconsumption,regress lag(3) //控制序列相关，默认为lag(0)对应于DF

*第四种形式，有趋势项，有漂移项，啥都有
dfuller lconsumption,regress lag(3) trend

*第一种形式，没有漂移项，比较反常，一般不建议用)
dfuller lconsumption,regress nocon

*第三种形式，无趋势项，有漂移项
dfuller lconsumption,regress drift

*注意第三种形式和第二种形式都是无趋势，有漂移，两者的回归结果完全一样，但是临界值不一样。检验统计量也一样。所以p值稍有差别

dfuller D.lconsumption
dfuller D.lconsumption, trend //可以看到一阶差分以后完全是平稳的









