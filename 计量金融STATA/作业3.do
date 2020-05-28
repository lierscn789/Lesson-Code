cd C:\Users\yecha\Documents\金融计量
import excel using EX6_4.xls ,first clear
renvars 日期  \ time 
renvars sh收盘 sz收盘\sh sz 

gen date=date(time,"YMD")
drop time 
format date %td
gen rh = ln(shsp/L.shsp)
gen rz = ln(szsp/L.szsp)

// bys stkcd (date): gen t = _n
// xtset stkcd t

tsset date
sort date 
*把行数也变成时间，否则在L1时候光靠date会产生很多缺失值
gen t=_n
tsset t 

drop rh rz
gen rh = ln(sh/L.sh)
gen rz =ln(sz/L.sz)

line rh date , ytitle("上海收益率")

line rz date , ytitle("深圳收益率")

sum rh ,detail
sum rz, detail
histogram rh ,normal
kdensity rh, normal lw(thick)
histogram rz ,normal
qnorm rh, grid
archqq rh //同样也是QQ图

*检验平稳性
dfuller rh 
dfuller rz


*自回归
reg rh
archlm, lag(1/15) //等价于estat archlm 
estat archlm ,lag(1/15)

regress rh L(1/15).rh
estat archlm ,lag(1/15)

regress rz L(1/15).rz
estat archlm ,lag(1/15)


cap drop e
cap drop e2
reg rh
predict e, res
gen e2 = e^2
reg e L(1/15).e
reg e2 L(1/15).e2

local LM = e(N)*e(r2)
dis in g "chi2(" in y "`e(df_m)'" in g ") = " in y %6.3f `LM' ///
in g " p-value = " in y %6.4f chi2(`LM', e(df_m))


line e2 date , ytitle("残差时序图")


arch rh, arch(1/6)
arch rh, arch(1/15)
archqq //生成arch标准化后的残差分布图

arch rh , arch(1) garch(1)
arch rz , arch(1) garch(1)

arch rh, nolog arch(1) garch(1) archm
predict GARCH01, variance 

arch rz, nolog arch(1) garch(1) archm
predict GARCH02, variance 

*TGARCH
constraint define 1 [ARCH]l1.arch + [ARCH]l1.garch = 1
arch rh, arch(1) garch(1) constraint(1)


var GARCH01 GARCH02,lag(1/2) dfk small
vargranger

arch rh, nolog arch(1) garch(1) archm