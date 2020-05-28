

******************************************************************************************

************************************************************************************
***说明1：本段程序用于读取2012年42部门投入产出表，并将结果存储于矩阵中
***说明2：矩阵名称与表3-1一致，如X表示中间投入矩阵，fl_in表示调入
***说明3：每个完整矩阵的调用格式为"name_id"，name表示矩阵名，id为地区代码
***说明4：地区代码见数据文件dist_code.dta文件。
************************************************************************************

cd "C:\Users\yecha\Downloads\Compressed\长三角县级\地区&地区间投入产出表（历年）\中国地区投入产出表2012\zk\html"
set more off


*获取所有excel文件名
local ff : dir . files "*.xls"
***建立代码库
local id=0
foreach file of local ff{
	local id=`id'+1
	local f`id'="`file'"
}
clear
set obs `id'
gen dist=""
gen id=_n
forval i=1/`id'{
	qui replace dist="`f`i''" in `i'
}
save dist_code.dta,replace

*约定部门数
local bm=42

local id=0
foreach file of local ff{
	local id=`id'+1
	import excel using "`file'", clear
	* fn 记录该文件对应哪个地区哪年的投入产出表
	local fn=A[1]
	drop in 1/9

	syntax [varlist]
	local i=1
	foreach var of local varlist{
		if "`var'"=="A"	|"`var'"=="B" |"`var'"=="C"{
			continue
		}
		gen bm`i'=real(`var')
		local i=`i'+1
	}
	
	***中间流量矩阵
	mkmat bm1-bm`bm'  in 1/`bm',mat(X_`id')
	
	***最终使用向量(消费、投资、出口)
	*最后一个部门右移6列
	local k=`bm'+6 
	mkmat bm`k'  in 1/`bm',mat(f1_`id')
	*最后一个部门右移9列*
	local k=`bm'+9 
	mkmat bm`k'  in 1/`bm',mat(f2_`id')
	*最后一个部门右移10列
	local k=`bm'+10 
	mkmat bm`k'  in 1/`bm',mat(f3_`id')
	
	*最后一个部门右移12列
	local k=`bm'+12 
	mkmat bm`k'  in 1/`bm',mat(tf_`id')
	
	
	***流入、流出、出口
	*最后一个部门右移11列
	local k=`bm'+11 
	mkmat bm`k'  in 1/`bm',mat(fl_out_`id')
	*最后一个部门右移13列
	local k=`bm'+13 
	mkmat bm`k'  in 1/`bm',mat(m_`id')
	*最后一个部门右移14列
	local k=`bm'+14 
	mkmat bm`k'  in 1/`bm',mat(fl_in_`id')
	
	***总产出
	*最后一个部门右移16列
	local k=`bm'+16 
	mkmat bm`k'  in 1/`bm',mat(q_`id')

	***增加值向量
	*最后一个部门下移2行
	local k=`bm'+2 
	mkmat bm1-bm`bm'  in `k' ,mat(y1_`id')
	*最后一个部门下移3行
	local k=`bm'+3 
	mkmat bm1-bm`bm'  in `k' ,mat(y2_`id')
	*最后一个部门下移4行
	local k=`bm'+4 
	mkmat bm1-bm`bm'  in `k' ,mat(y3_`id')
	*最后一个部门下移5行
	local k=`bm'+5 
	mkmat bm1-bm`bm'  in `k' ,mat(y4_`id')
	*最后一个部门下移6行
	local k=`bm'+6 
	mkmat bm1-bm`bm'  in `k' ,mat(y_`id')
}


*********
*检查数据
*(1)各省投入产出表内，调入和进口占(中间+最终使用)的比例
clear
forval i=9/12{
	*占（中间使用+最终使用）比重
	mat r1_`i'=invsym(diag(X_`i'*J(`bm',1,1)+tf_`i'))*(fl_in_`i'+m_`i')
	*占（中间使用+不含出口和调出的最终使用）比重
	mat r2_`i'=invsym(diag(X_`i'*J(`bm',1,1)+f1_`i'+f2_`i'))*(fl_in_`i'+m_`i')
	svmat  r1_`i'
	svmat  r2_`i'
}

*(2)所有省份的进出口结构，及其与全国进出口总额的比较
clear
forval i=1/32{
	svmat m_`i'
	svmat f3_`i'
}
order m* f*
egen mtot=rowtotal(m_11-m_311)
egen f3tot=rowtotal(f3_11-f3_311)

gen m_csj=m_91+m_101+m_111+m_121
gen f3_csj=f3_91+f3_101+f3_111+f3_121

*长三角的进口占全国比重
gen mr1=m_csj/mtot
gen mr2=m_csj/m_321
gen mr=mtot/m_321
*长三角的出口占全国比重
gen f3r1=f3_csj/f3tot
gen f3r2=f3_csj/f3_321
gen f3r=f3tot/f3_321

*(3)所有省份的中间使用，与全国中间使用的比较
clear
mat Xtot=J(`bm',`bm',0)
forval i=1/31{
	mat Xtot=Xtot+X_`i'
}
mat X1delta=Xtot-X_32

mat Xcsj=J(`bm',`bm',0)
forval i=9/12{
	mat Xcsj=Xcsj+X_`i'
}

mat X2delta=Xcsj-X_32

capture mat drop invXT
forval i=1/`bm'{
	mat invd=vecdiag(invsym(diag(X_32[....,`i'])))
	mat invXT=(nullmat(invXT),invd')
}

mat rXcsj=hadamard(Xcsj,invXT)
mat rXtot=hadamard(Xtot,invXT)

capture mat drop invXT
forval i=1/`bm'{
	mat invd=vecdiag(invsym(diag(Xtot[....,`i'])))
	mat invXT=(nullmat(invXT),invd')
}
mat rateofcsj=hadamard(Xcsj,invXT)



**********************************************************************************************
***开发一个RAS程序。

capture program drop RAS
program RAS
*按顺序输入参数：初始矩阵、目标列和与行和向量，以及输出矩阵名
args Xmat Vec_csum Vec_rsum Mout 
*定义调整矩阵和目标行、列和
mat RAS=`Xmat'
mat cs=`Vec_csum'
mat rs=`Vec_rsum'
local num=colsof(RAS)
mat i=J(`num',1,1)

preserve
clear
svmat cs
svmat rs
qui replace cs1=1 if cs1>0
qui replace rs1=1 if rs1>0
mkmat rs1,matrix(r_lamda)
mkmat cs1,matrix(c_lamda)
restore

mat r_sum=RAS*i
mat c_sum=RAS'*i
	
mat r_coef=invsym(diag(r_sum))*rs
mat c_coef=invsym(diag(c_sum))*cs
mat coef=(r_coef-J(`num',1,1))'*diag(r_lamda)*(r_coef-J(`num',1,1))+(c_coef-J(`num',1,1))'*diag(c_lamda)*(c_coef-J(`num',1,1))	
local coef=coef[1,1]

local n=0

while abs(`coef')>0.0001{
	mat RAS=diag(r_coef)*RAS
	mat c_sum=RAS'*i
	mat c_coef=invsym(diag(c_sum))*cs
	mat RAS=RAS*diag(c_coef)
	
	mat r_sum=RAS*i
	mat c_sum=RAS'*i
	
	mat r_coef=invsym(diag(r_sum))*rs
	mat c_coef=invsym(diag(c_sum))*cs
	mat coef=(r_coef-J(`num',1,1))'*diag(r_lamda)*(r_coef-J(`num',1,1))+(c_coef-J(`num',1,1))'*diag(c_lamda)*(c_coef-J(`num',1,1))	
	local coef=coef[1,1]
	*mat t=(r_sum,rs,r_coef,c_sum,cs,c_coef)
	*mat list t
	*超100次不收敛，则退出
	local n=`n'+1
	if `n'>100{
		di "`n'th looping: `coef'"
	}
	if `n'>300{
		di "`Xmat' ：不收敛"
		mat RAS_`Mout'=diag(r_coef)*RAS*diag(c_coef)
		continue,break
	}
}
mat RAS_`Mout'=diag(r_coef)*RAS*diag(c_coef)

end


***************************************************************
***从31省42部门表提取用于引力模型回归的数据

 local A=9
 local B=10
 local C=11
 local D=12

 
***从31省区域间投入产出表读取数据 
import excel "C:\Users\yecha\Downloads\Compressed\长三角县级\地区&地区间投入产出表（历年）\ChinaMRIO 31province42sectors_刘卫东.xlsx", sheet("2012MRIO")  first  clear

*变量名更换
syntax [varlist]
local id=0
foreach v of local varlist{
	local id=`id'+1
	ren `v' v`id'
}

drop v1
syntax [varlist]
local id=0
foreach v of local varlist{
	local id=`id'+1
	ren `v' c`id'
}

*读取表内贸易矩阵数据
forval g=1/31{

	forval h=1/31{
	
		local c1=(`h'-1)*42+1
		local c2=`h'*42
		local r1=(`g'-1)*42+1
		local r2=`g'*42

		mkmat c`c1'-c`c2' in `r1'/`r2' ,matrix(X_`g'to`h')
		
		local c1=31*42+(`h'-1)*4+1
		local c2=31*42+`h'*4
		local r1=(`g'-1)*42+1
		local r2=`g'*42
		
		mkmat c`c1'-c`c2' in `r1'/`r2' ,matrix(F_`g'to`h')
	}
}



*提取长三角三省一市的数据
foreach g in "A" "B" "C" "D"{
	foreach h in "A" "B" "C" "D"{
		mat X_`g'`h'=X_``g''to``h''
		mat F_`g'`h'=F_``g''to``h''
	}
}
*合并长三角外的其他地区的数据
foreach g in "A" "B" "C" "D"{
	mat X_`g'E=J(42,42,0)
	mat F_`g'E=J(42,4,0)
	mat X_E`g'=J(42,42,0)
	mat F_E`g'=J(42,4,0)
	
	forval j=1/31{
		if `j'>=9 & `j'<=12{
			continue
		}
		mat X_`g'E=X_`g'E+X_``g''to`j'
		mat F_`g'E=F_`g'E+F_``g''to`j'
		mat X_E`g'=X_E`g'+X_`j'to``g''
		mat F_E`g'=F_E`g'+F_`j'to``g''
	}

}

mat X_EE=J(42,42,0)
mat F_EE=J(42,4,0)

forval i=1/31{
		if `i'>=9 & `i'<=12{
			continue
		}
	forval j=1/31{
		if `j'>=9 & `j'<=12{
			continue
		}
		mat X_EE=X_EE+X_`i'to`j'
		mat F_EE=F_EE+F_`i'to`j'
	}

}

*计算按部门的地区to地区的流入流出数据（不分去向，即中间使用+最终使用）
clear
foreach g in "A" "B" "C" "D" "E"{
	capture mat drop X_`g'
	capture mat drop F_`g'

	foreach h in "A" "B" "C" "D" "E"{
		mat X_`g'=(nullmat(X_`g'),X_`g'`h')
		mat F_`g'=(nullmat(F_`g'),F_`g'`h')
		mat fl_`g'`h'=X_`g'`h'*J(42,1,1)+F_`g'`h'*(1,1,1,0)'
		
		if "`g'"=="`h'"{
			mat fl_`g'`h'=J(42,1,0)
		}

		svmat fl_`g'`h'
	}
}

foreach g in "A" "B" "C" "D" "E"{
	mat fl_out_`g'=J(`bm',1,0)
	mat fl_in_`g'=J(`bm',1,0)
	foreach h in "A" "B" "C" "D" "E"{
		mat fl_out_`g'= fl_out_`g'+fl_`g'`h'
		mat fl_in_`g'= fl_in_`g'+fl_`h'`g'
	}
	svmat fl_out_`g'
	svmat fl_in_`g'
}

*合成得到关于流入流出（分部门，有地区流向）的综合矩阵
capture mat drop FL
foreach g in "A" "B" "C" "D" "E"{
	capture mat drop FL_`g'
	foreach h in "A" "B" "C" "D" "E"{
		mat FL_`g'=(nullmat(FL_`g'), diag(fl_`g'`h'))
	}
	mat FL=(nullmat(FL) \ FL_`g')
}




************************************************************************
*ABCD四地区的总流入流出是已知的。
*需推算E地区的总流入和流出
*假设长三角各地区对E的流入和流出占比不变

*是否将安徽第42部门的调出数据调整为0。属于问题数据，因为其他地区的调入调出均为0。
*mat fl_out_12[42,1]=0

foreach g in "A" "B" "C" "D"{
	mat Rfl_out_`g'=fl_out_``g''
	mat Rfl_in_`g'=fl_in_``g''
	
	capture mat drop TC
	capture mat drop TR

	foreach h in "A" "B" "C" "D" "E"{
		if "`h'"=="`g'"{
			continue
		}
		mat TR=(nullmat(TR),fl_`g'`h')
		mat TC=(nullmat(TC),fl_`h'`g')
	}
	clear
	svmat TR
	svmat TC
	*计算g地区中，对长三角以外的调出或调入占比
	gen rr=TR4/sum(TR1+TR2+TR3+TR4)
	gen cr=TC4/sum(TC1+TC2+TC3+TC4)
	mkmat rr,matrix(rr_`g')
	mkmat cr,matrix(cr_`g')	
}

*按比例，汇总E地区的调入调出
mat Rfl_in_E=J(42,1,0)
mat Rfl_out_E=J(42,1,0)
foreach g in "A" "B" "C" "D"{
	*E地区的调入为其他四地区对其调入之和，其调出同理。	
	mat Rfl_out_E=Rfl_out_E+diag(rr_`g')*Rfl_in_`g'
	mat Rfl_in_E=Rfl_in_E+diag(cr_`g')*Rfl_out_`g'
		*mat list Rfl_in_E
}
********
*需要平衡调整，确保每种产品的总调入=总调出。这样才能做RAS

mat tflin=Rfl_in_A+Rfl_in_B+Rfl_in_C+Rfl_in_D+Rfl_in_E
mat tflout=Rfl_out_A+Rfl_out_B+Rfl_out_C+Rfl_out_D+Rfl_out_E

mat tin0=(Rfl_in_A,Rfl_in_B,Rfl_in_C,Rfl_in_D,Rfl_in_E,tflin)
mat tout0=(Rfl_out_A,Rfl_out_B,Rfl_out_C,Rfl_out_D,Rfl_out_E,tflout)

*主要针对E地区的调入调出
mat delta=tflin-tflout

forval i=1/`bm'{
	if delta[`i',1]>0{
		mat Rfl_out_E[`i',1]=Rfl_out_E[`i',1]+delta[`i',1]
	}
	if delta[`i',1]<0{
		mat Rfl_in_E[`i',1]=Rfl_in_E[`i',1]-delta[`i',1]
	}
}

mat tflin=Rfl_in_A+Rfl_in_B+Rfl_in_C+Rfl_in_D+Rfl_in_E
mat tflout=Rfl_out_A+Rfl_out_B+Rfl_out_C+Rfl_out_D+Rfl_out_E

mat tin1=(Rfl_in_A,Rfl_in_B,Rfl_in_C,Rfl_in_D,Rfl_in_E,tflin)
mat tout1=(Rfl_out_A,Rfl_out_B,Rfl_out_C,Rfl_out_D,Rfl_out_E,tflout)


foreach g in "A" "B" "C" "D"{
	mat infl=Rfl_in_`g'
	mat outfl=tflout-Rfl_out_`g'
	forval i=1/`bm'{
		if infl[`i',1]>outfl[`i',1]{
			mat Rfl_out_E[`i',1]=Rfl_out_E[`i',1]+infl[`i',1]-outfl[`i',1]
			mat Rfl_in_E[`i',1]=Rfl_in_E[`i',1]+infl[`i',1]-outfl[`i',1]
		}	
	}	
}

mat tflin=Rfl_in_A+Rfl_in_B+Rfl_in_C+Rfl_in_D+Rfl_in_E
mat tflout=Rfl_out_A+Rfl_out_B+Rfl_out_C+Rfl_out_D+Rfl_out_E

mat tin2=(Rfl_in_A,Rfl_in_B,Rfl_in_C,Rfl_in_D,Rfl_in_E,tflin)
mat tout2=(Rfl_out_A,Rfl_out_B,Rfl_out_C,Rfl_out_D,Rfl_out_E,tflout)

mat list tin0
mat list tin1
mat list tin2


mat Rfl_in=(Rfl_in_A\Rfl_in_B\Rfl_in_C\Rfl_in_D\Rfl_in_E)
mat Rfl_out=(Rfl_out_A\Rfl_out_B\Rfl_out_C\Rfl_out_D\Rfl_out_E)

**************************************************************************************
***估计引力模型的参数
*地区间距离数据(数据来源：？？？)
import excel using "C:\Users\yecha\Downloads\Compressed\长三角县级\各省会距离.xls",cellrange(D2:AH32) clear
mkmat * ,matrix(dist)

foreach g in "A" "B" "C" "D"{
	foreach h in "A" "B" "C" "D"{
		local `g'`h'=dist[``g'',``h'']
	}
}
local EE=0


foreach g in "A" "B" "C" "D"{
	local d=0
	forval i=1/31{
		if (`i'>8 & `i'<13)|(`i'>23) {
			continue
		}
		local d=`d'+dist[``g'',`i']
	}
	local `g'E=`d'/19
	local E`g'=`d'/19
}



*基于地区投入产出表获取长三角+外地区的总流入和总流出
 local A=9
 local B=10
 local C=11
 local D=12
 local E=32
local i=0

capture mat drop YX
foreach g in "A" "B" "C" "D" "E"{
	local i=`i'+1
	local j=0
	foreach h in "A" "B" "C" "D" "E"{
		local j=`j'+1
		local r1=(`i'-1)*`bm'+1
		local r2=`i'*`bm'
		local c1=(`j'-1)*`bm'+1
		local c2=`j'*`bm'
		
		mat fl_`g'`h'=FL[`r1'..`r2',`c1'..`c2']*J(`bm',1,1)
		
		*7个变量的顺序：1.A->B地的产品，2.A地的总流出，3.B地的总流入，4.AB两地的距离，
						*5.A地的实际总流出，6.B地的实际总流入，7.地区标签。
		*mat YX_`g'`h'=(fl_`g'`h',fl_out_`g',fl_in_`h',J(`bm',1,``g'`h''),Rfl_out_`g',Rfl_in_`h',J(`bm',1,`i'`j'))
		mat YX_`g'`h'=(Rfl_out_`g',Rfl_in_`h',J(`bm',1,``g''),J(`bm',1,``h''),J(`bm',1,``g'`h''))
		mat YX=(nullmat(YX) \ YX_`g'`h')	
	}	
}

clear
svmat YX
ren YX1 real_x1
ren YX2 real_x2
ren YX3 g
ren YX4 h
ren YX5 dist

gen bm=mod(_n-1,42)+1
save realdata.dta,replace

***基于31省区域间表获取长三角与各省之间的流入流出数据
clear
forval g =1/31{

	forval h =1/31{

		mat fl_`g'to`h'=X_`g'to`h'*J(42,1,1)+F_`g'to`h'*(1,1,1,0)'
		
		if "`g'"=="`h'"{
			mat fl_`g'to`h'=J(42,1,0)
		}

		svmat fl_`g'to`h'
	}
}

forval g =1/31{
	mat tfl_out_`g'=J(`bm',1,0)
	mat tfl_in_`g'=J(`bm',1,0)
	forval h =1/31{
		mat tfl_out_`g'= tfl_out_`g'+fl_`g'to`h'
		mat tfl_in_`g'= tfl_in_`g'+fl_`h'to`g'
	}

}


capture mat drop YX
forval g =1/31{

	forval h =1/31{
		if (`g'<9 | `g'>12) & (`h'<9 |`h'>12){
			continue
		}
		
		*7个变量的顺序：1.A->B地的产品，2.A地的总流出，3.B地的总流入，4.AB两地的距离，
						*5.A地的实际总流出，6.B地的实际总流入，7.地区标签。
		mat YX_`g'to`h'=(fl_`g'to`h',tfl_out_`g',tfl_in_`h',J(`bm',1,dist[`g',`h']),J(`bm',1,`g'),J(`bm',1,`h'))	
		mat YX=(nullmat(YX) \ YX_`g'to`h')	
	}	
	clear 
	svmat YX
	mat drop YX
	save `g'.dta,replace
}


clear
forval g=1/31{
	append using `g'.dta
}
ren YX5 g
ren YX6 h
gen bm=mod(_n-1,42)+1
merge 1:1 g h bm using realdata

gen y=ln(YX1)
gen X1=ln(YX2)
gen X2=ln(YX3)
gen X3=ln(YX4)

*窗宽的确定还需要更多的考虑
gen w=exp(-(YX4)^2/1000000)

gen p_y=.

forval i=1/42{
	di `i'

	 reg y X1 X2 -X3 [aweight=w]  if mod(_n-1,42)==`i'
	if _rc!=0{
		continue
	}
	local b0=r(table)[1,4]
	local b1=r(table)[1,1]
	local b2=r(table)[1,2]
	local b3=r(table)[1,3]

	qui replace p_y=exp(`b0')*((real_x1)^`b1')*((real_x2)^`b2')/((dist)^`b3') if mod(_n-1,42)+1==`i'
		
}	


local i=0
 local A=9
 local B=10
 local C=11
 local D=12
 local E=32
 local bm=42
replace p_y=0 if p_y==.
drop if real_x1==.
sort g h
order g h YX1 p_y
*将两地区间流量为0的数值替换为1.
replace p_y=1 if p_y==0 & (g!=h)


*提取估计后的区域间流量（ABCD四地区间）

 
foreach g in "A" "B" "C" "D" "E"{
	local i=`i'+1
	local j=0
	foreach h in "A" "B" "C" "D" "E"{
		local j=`j'+1
		local r1=(`i'-1)*210+(`j'-1)*`bm'+1
		local r2=(`i'-1)*210+`j'*`bm'
		
		mkmat p_y in `r1'/`r2',matrix(est_fl_`g'`h')
	}
}

**************************************************************************
******RAS调整
capture mat drop est_FL
foreach g in "A" "B" "C" "D" "E"{
	capture mat drop est_FL_`g'
	foreach h in "A" "B" "C" "D" "E"{
		mat est_FL_`g'=(nullmat(est_FL_`g'), diag(est_fl_`g'`h'))
	}
	mat est_FL=(nullmat(est_FL) \ est_FL_`g')
}

RAS est_FL Rfl_in Rfl_out est_FL


*分解成5*5的子矩阵（分部门）
clear
foreach g in "A" "B" "C" "D" "E"{
	foreach h in "A" "B" "C" "D" "E"{
		svmat est_fl_`g'`h'
	}	
}

local bm=42

forval i=1/`bm'{
	foreach g in "A" "B" "C" "D" "E"{
		mkmat est_fl_`g'* in `i',matrix(r`g')
	}
	mat est_FL_`i'=(rA\rB\rC\rD\rE)
}



forval i=1/`bm'{
	mat Rfl_in_`i'=(Rfl_in_A[`i',1]\Rfl_in_B[`i',1]\Rfl_in_C[`i',1]\Rfl_in_D[`i',1]\Rfl_in_E[`i',1])
	mat Rfl_out_`i'=(Rfl_out_A[`i',1]\Rfl_out_B[`i',1]\Rfl_out_C[`i',1]\Rfl_out_D[`i',1]\Rfl_out_E[`i',1])
}



forval i=1/`bm'{
	di "第`i'个部门："
	RAS est_FL_`i' Rfl_in_`i' Rfl_out_`i' est_FL_`i' 
	mat t=(est_FL_`i' ,Rfl_in_`i' ,Rfl_out_`i')
	mat list t
	mat list RAS_est_FL_`i' 
}



****************************************************************************
***提取地区间的贸易流量向量fl_`g'`h'
local i=0
foreach g in "A" "B" "C" "D" "E"{
	local i=`i'+1
	local j=0
	foreach h in "A" "B" "C" "D" "E"{
		local j=`j'+1
		local r1=(`i'-1)*`bm'+1
		local r2=`i'*`bm'
		local c1=(`j'-1)*`bm'+1
		local c2=`j'*`bm'
		
		mat est_fl_`g'`h'=RAS_est_FL[`r1'..`r2',`c1'..`c2']*J(`bm',1,1)
		
		*如果g->h流量小于1，将其调整为0。
		forval k=1/`bm'{
			if est_fl_`g'`h'[`k',1]<1{
				mat est_fl_`g'`h'[`k',1]=0
			}
		
		}
	}
}

foreach g  in "A" "B" "C" "D" "E"{
	di "`g'"
	mat tin`g'=(est_fl_A`g',est_fl_B`g',est_fl_C`g',est_fl_D`g',est_fl_E`g')*(1,1,1,1,1)'
	mat r=invsym(diag(tin`g'))*diag(Rfl_in_`g')
	foreach h in "A" "B" "C" "D" "E"{
	di "`h'"
		mat est_fl_`h'`g'=r*est_fl_`h'`g'
	}	
}



***********************************************************************************************
**将调入和进口按比例法分配于中间使用和最终使用

 foreach g in "A" "B" "C" "D" {
	mat X_`g'=X_``g''
	mat tf_`g'=tf_``g''
	mat m_`g'=m_``g''
 }

 	
 mat yT=J(5,42,0)
 foreach g in "A" "B" "C" "D"{
	mat y_`g'=(y1_``g''\y2_``g''\y3_``g''\y4_``g''\y_``g'')
	mat yT=yT+y_`g'
	mat q_`g'=q_``g''
 }
 

 
 **此处还需要进一步处理
	mat X_E=J(42,42,0)
	mat tf_E=J(42,1,0)
	mat m_E=J(42,1,0)
	mat y_E=J(5,42,0)
	mat q_E=J(42,1,0)

	forval i=1/31{
		if `i'>8 & `i'<13{
			continue
		}
		foreach mt in "X" "tf" "m" "q"{
			mat `mt'_E=`mt'_E+`mt'_`i'
		}
	mat y_E=y_E+(y1_`i'\y2_`i'\y3_`i'\y4_`i'\y_`i')
	}

 
	
	
	
foreach h in "A" "B" "C" "D" "E"{

	mat alc=(X_`h',tf_`h')
	
	
	local num=`bm'+1
	local c1=`bm'+1
	*零矩阵，存储对外地区的使用
	mat alc_out=J(`bm',`num',0)
	mat rs=alc*J(`num',1,1)

	*流入地的分配比例矩阵
	mat alc_coef_`h'=inv(diag(rs))*alc
	
	foreach g in "A" "B" "C" "D" "E"{
		if "`g'"=="`h'"	{
			continue
		}
		mat alc_`g'`h'=diag(est_fl_`g'`h')*alc_coef_`h'
		mat alc_out=alc_out+alc_`g'`h'
		
		mat X_`g'`h'=alc_`g'`h'[....,1..`bm']
	
		mat tf_`g'`h'=alc_`g'`h'[....,`c1']
	}
	

	***对进口的处理
	mat malc_`h'=diag(m_`h')*alc_coef_`h'
	mat Xm_`h'`h'=malc_`h'[....,1..`bm']
	mat tfm_`h'`h'=malc_`h'[....,`c1']
	
	mat alc_`h'`h'=alc-alc_out-malc_`h'
	
	mat X_`h'`h'=alc_`h'`h'[....,1..`bm']
	mat tf_`h'`h'=alc_`h'`h'[....,`c1']
	
}


foreach h in "A" "B" "C" "D" "E"{
	foreach g in "A" "B" "C" "D" "E"{
		
		forval i=1/`bm'{
			
			mat tf_`h'`h'[`i',1]=round(tf_`h'`h'[`i',1],0.01)
			
			forval j=1/`bm'{
				 mat X_`h'`h'[`i',`j']=round(X_`h'`h'[`i',`j'],0.01)
			}
		
		}

}
}

*****************************************************
***提取5区域间IO-table
/*
capture mat drop X_RR 
capture mat drop F_RR 
capture mat drop Y_RR 
capture mat drop Q_RR

 foreach g in "A" "B" "C" "D" "E"{
	capture mat drop X_`g'
	capture mat drop tf_`g' 
	foreach h in "A" "B" "C" "D" "E"{
		mat X_`g'=(nullmat(X_`g'),X_`g'`h')
		mat tf_`g'=(nullmat(tf_`g'),tf_`g'`h')
	}
	mat X_RR=(nullmat(X_RR) \ X_`g')
	mat F_RR=(nullmat(F_RR) \ tf_`g')
	mat Q_RR=(nullmat(Q_RR) \ q_`g')
}
	
	mat Y_RR=(y_A,y_B,y_C,y_D,y_E)

	mat Fm_RR=(tfm_AA,tfm_BB,tfm_CC,tfm_DD,tfm_EE)
	mat F_RR=(F_RR\Fm_RR)
	mat Q_RR=(Q_RR\m_32)
	mat mX=(Xm_AA,Xm_BB,Xm_CC,Xm_DD,Xm_EE)

clear
mat col=(X_RR\mX\Y_RR)
svmat col 
svmat F_RR
svmat Q_RR

export excel "D:\SUFECloud Cache\郑正喜\AA项目专用\上海市统计局课题\投入产出课题共享链接\输出数据-长三角地区间投入产出表.xlsx", sheet("Sheet1",modify) cell(D4)
 
 clear
svmat Rfl_out
export excel "D:\SUFECloud Cache\郑正喜\AA项目专用\上海市统计局课题\投入产出课题共享链接\输出数据-长三角地区间投入产出表.xlsx", sheet("Sheet1",modify) cell(HP4)
 
 clear
 svmat  Rfl_in
export excel "D:\SUFECloud Cache\郑正喜\AA项目专用\上海市统计局课题\投入产出课题共享链接\输出数据-长三角地区间投入产出表.xlsx", sheet("Sheet1",modify) cell(HT4)
 
 */

 
 
 foreach h in "A" "B" "C" "D" "E"{ 
	*E地区调出到ABCD的中间使用合并一行。
	mat X_E`h'=J(1,42,1)*X_E`h'
	*E地区的调入合并一列。
	mat X_`h'E=X_`h'E*J(42,1,1)
	*E地区最终使用的调出合并一个数。
	mat tf_E`h'=J(1,42,1)*tf_E`h'
 }
 
   
 mat q_E=J(1,42,1)*q_E
 mat y_E=y_E*J(42,1,1)
 
capture mat drop X_RR 
capture mat drop F_RR 
capture mat drop Y_RR 
capture mat drop Q_RR

 foreach g in "A" "B" "C" "D" "E"{
	capture mat drop X_`g'
	capture mat drop tf_`g' 
	foreach h in "A" "B" "C" "D" "E"{
		mat X_`g'=(nullmat(X_`g'),X_`g'`h')
		mat tf_`g'=(nullmat(tf_`g'),tf_`g'`h')
	}
	mat X_RR=(nullmat(X_RR) \ X_`g')
	mat F_RR=(nullmat(F_RR) \ tf_`g')
	mat Q_RR=(nullmat(Q_RR) \ q_`g')
}
	
	mat Y_RR=(y_A,y_B,y_C,y_D,y_E)

	*添加进口行
	mat Xm_EE=Xm_EE*J(42,1,1)

	mat mX=J(1,42,1)*(Xm_AA,Xm_BB,Xm_CC,Xm_DD,Xm_EE)
	
	mat Fm_RR=J(1,42,1)*(tfm_AA,tfm_BB,tfm_CC,tfm_DD,tfm_EE)
	mat F_RR=(F_RR\Fm_RR)

clear
*展示和检查最终结果
*行的顺序：共175行（中间投入，ABCD四地区各42行，E地区1行，进口1行；最初投入：增加值5行。）
*列的顺序：共175列（中间使用：ABCD四地区各42列，E地区1列；最终使用，ABCDE各1列；总产出1列）
*下面四句话可以产生最后数据
mat col=(X_RR\mX\Y_RR)

svmat col 
svmat F_RR
svmat Q_RR


*检查负数
syntax [varlist]

foreach var of local varlist{
	qui replace `var'=. if `var'>=0
}

egen sum=rowtotal(*)
gen n=_n

drop if sum==0