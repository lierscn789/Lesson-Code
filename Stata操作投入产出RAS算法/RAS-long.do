clear
local bm=42

foreach g in "A" "B" "C" "D" "E"{
	foreach h in "A" "B" "C" "D" "E"{	
		mat fl_`g'`h'=100*matuniform(`bm',1)
		if "`g'"=="`h'"{
			mat fl_`g'`h'=J(`bm',1,0)
		}
		*向量对角化
		mat Dfl_`g'`h'=diag(fl_`g'`h')
	}
	*矩阵并排
	mat F_`g'=(Dfl_`g'A,Dfl_`g'B,Dfl_`g'C,Dfl_`g'D,Dfl_`g'E)
}
*矩阵堆栈
mat F=(F_A\F_B\F_C\F_D\F_E)

*通过数据查看矩阵堆栈结果
svmat F

*虚拟生成各地的流入流出数据
foreach g in "A" "B" "C" "D" "E"{	
	mat fl_in_`g'=J(`bm',1,400)
	mat fl_out_`g'=J(`bm',1,300)
}
*向量堆栈
mat fl_in=(fl_in_A\fl_in_B\fl_in_C\fl_in_D\fl_in_E)
mat fl_out=(fl_out_A\fl_out_B\fl_out_C\fl_out_D\fl_out_E)






**********************************
mata
 

primat=st_matrix("F") //获取初始贸易流量矩阵5地区x5地区
hanghe=st_matrix("fl_out")' //获取每一行的和
liehe=st_matrix("fl_in")'

m=200 //迭代次数


function rasalgorithm(m) 
{
hangratediag=J(1,cols(hanghe),1) //初始化接受行列调整矩阵，这里都设置成了行向量
lieratediag=J(1,cols(liehe),1) 

for (i=1; i<=m; i++) {

hangsum=rowsum(primat) //计算行和，这里生成的都是列向量
hangrate=hanghe':/hangsum //计算行调整比例,hanghe为行向量转置后hangrate为列向量
hangratediag=hangratediag :*hangrate' //累积行调整比例，:*表示对应元素两两相乘列向量转置，这里要和之前初始化的hangratediag对应
primat=primat :* hangrate //行调整更新初始矩阵，这里hangrate是列向量，因此是每行调整
hangrate //可以看一下当时的行调整比例是否接近1



//下面是列调整，计算列调整累积系数
liesum=colsum(primat) 
lierate=liehe:/liesum 
lieratediag=lieratediag :*lierate
primat=primat :*lierate    


}
hangmat=diag(hangratediag) //把累积的系数生成对角矩阵
liemat=diag(lieratediag)
hangmat //查看
liemat
primat=hangmat*primat*liemat //进行RAS操作
primat //看看结果
printf("done\n")
}


end


