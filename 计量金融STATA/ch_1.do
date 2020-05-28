cd "C:/Users/yecha/Documents/金融计量"
use grilic.dta,clear
browse
describe

summarize lnw s expr tenure rns smsa

reg lnw s expr tenure rns smsa

mat list e(b)
ereturn list //返回值,返回的是电子表格 	`'

vce //显示回归系数的协方差矩阵

reg lnw s expr tenure rns smsa ,nonconstant //进行无常数项回归

reg lnw s expr tenure rns smsa if rns //只对南方居民的子样本进行回归，可以看到tenure参数非显著，说明出现了共线性

reg lnw s expr tenure rns smsa if ~rns 

reg lnw s expr tenure rns smsa if s>=12//只对中学以上的子样本进行回归

reg lnw s expr tenure rns smsa if s>=12 & rns //中学以上并且是南方的

*预测


quietly reg lnw s expr tenure rns smsa //表示不显示线性回归结果
 
predict name2 //拟合值'

predict e,residual //残差 ，注释与代码之间至少有一个空格

*若干有意义的检验

reg lnw s expr tenure rns smsa 

test s=0.1 //检验教育投资回报率是否为10%

test expr=tenure //检验expr与tenure的系数是否相同

test expr+tenure=s //检验工龄的回报率与现单位年限回报率之和是否等于教育回报率

*=========stata自动生成报告==========
/*
putdocx begin 生成.docx文件
toheader()
tofooter()
pagenum()
putdocx save 保存.docx文件

putdocx paragraph 
style 
font
halign
valign
indent 
spacing 
shading 
toheader 
tofooter 
*/

cscript   //脚本开始认证 (可略去)

putdocx begin  //生成.docx文件

putdocx paragraph, style("Heading1") font(, 24, green) halign(center) //产生段落
putdocx text ("重量和车长变量关系 - 线性回归")


sysuse auto, clear
browse
regress weight length


*1)regress结果导出到word

putdocx table t1 = etable



putdocx table t1(1, 2) = ("系数")
putdocx table t1(1, 3) = ("标准误差")
putdocx table t1(1, 6) = ("[95%置信区间]"), halign(center)
putdocx table t1(3, 1) = ("常数"), halign(right)
putdocx table t1(2 3, 2/7), nformat(%6.2f)
putdocx save ex1.docx, replace 

ereturn list
putdocx table t2 = escalars
putdocx save ex1.docx, replace 
















