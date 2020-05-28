#####Chapter3 Data preprocess################
library(stats) # 使用的函数stack & unstack
library(reshape2) # 使用的函数 melt & dcast 
library(tidyr)# 使用的gather & spread

##################################################
####1.1整齐数据
##################################################
##例1：奖金水平（宽型转长型）
setwd("C:/Users/yecha/Documents/Lendingclub")


##使用stack/unstack进行长、宽数据转换
## S3 method for class 'data.frame':  stack(x, select, ...)
## x a list or data frame to be stacked or unstacked.
##select an expression, indicating which variable(s) to select from a data frame.

bonus=read.table("bonus.txt",header=T)
head(bonus)
b.long=stack(bonus)
head(b.long)

unstack(b.long, values ~ ind)

##使用melt变换成长数据
b.long1=melt(bonus,
             variable.name='Levels', 
             value.name='Time')
##id_vars和 measure.vars只需要制定一个即可;另外一个默认是除指定的变量外的所有变量.
head(b.long1)
b.long1=b.long1[,c(2,1)]


##使用gather变换成长数据
##gather(data, key, value, …, na.rm = FALSE, convert = FALSE)
##data：需要被转换的宽表
##key：将原数据框中的所有列赋给一个新变量key
##value：将原数据框中的所有值赋给一个新变量value
##…：可以指定哪些列聚到同一列中
##na.rm：是否删除缺失值

b.long2=gather(bonus,'Levels', 'Time')
head(b.long2)

####例2. 宗教和收入
Religion=c("Agnostic","Atheist","Buddhist","Catholic","Unknown")
In010k=c(27,12,27,418,15)
In1020k=c(34,27,21,617,14)
In2030k=c(60,37,30,732,15)
In3040k=c(81,52,34,670,11)
In4050k=c(76,35,33,638,10)
In5070k=c(137,70,58,1116,35)
ReIn=data.frame(Religion,In010k,In1020k,In2030k,In3040k,In4050k,In5070k)
ReIn

ReIn.long=melt(ReIn,id.vars=c("Religion"),
               variable.name = "Income",value.name = "Frequency")
ReIn.long

#melt(ReIn,id=1)

dcast(ReIn.long,Religion ~ Income)

ReIn.long1<-gather(data=ReIn, key="Income", value="Frequency",-Religion)
ReIn.long1

spread(data=ReIn.long1, key="Income", value="Frequency")  

##################################################
####1.2批量数据的读入与预览 (dplyr)
##################################################
library(dplyr)
##批量读某文件夹下所有的文件
setwd("~/Lendingclub")

#path = "D:/MyTeaching/SHUFE/Courses/DataAnalysis/Dataanalysis_201819/DataandRcode/Data/Lendingclub"
#thefilesL=dir(path,pattern="^Loan") #获取文件夹中所有带有Loan字节的文件
thefilesL=dir(path = ".", pattern = "^Loan")
LoanList0=lapply(thefilesL,read.csv,stringsAsFactors=FALSE)
#str(LoanList0)

Loan=do.call(rbind,LoanList0) #按行合并不同csv文件的数据

#thefilesR=dir(path = ".", pattern = "^Reject")
#RejectList0=lapply(thefilesR,read.csv,stringsAsFactors=FALSE)

####数据的预览
str(Loan) #查看数据主要信息

Loan.df=tbl_df(Loan)  #生成一个data frame tibble 类型
Loan.df

####数据的基本操作
Loan.temp=mutate(Loan,intr=as.numeric(sub("%","",int_rate)))  #添加新的变量"intr"
head(Loan.temp$intr)

Loan.temp=mutate(Loan,int_rate=as.numeric(sub("%","",int_rate)),
                 term=as.numeric(sub("months","",term)))    #替换变量


Loan.s=select(Loan.temp,1:7)  #选择指定的列
Loan.s=select(Loan.temp,id:int_rate,addr_state)
Loan.s=select(Loan.s,-id)
head(Loan.s)

CA_Loan=filter(Loan.s,funded_amnt>=10000&addr_state=="CA")

Loan.s1=arrange(Loan.s,loan_amnt,funded_amnt_inv)     #升序排列
Loan.s2=arrange(Loan.s,desc(loan_amnt),funded_amnt_inv)  #loan_amnt降序
head(Loan.s1)
head(Loan.s2)

summarise(group_by(Loan,grade),               #使用分类变量grade分组
          ave.amnt=mean(funded_amnt,na.rm = TRUE),  
          sd=sd(funded_amnt,na.rm = TRUE),
          n=sum(!is.na(funded_amnt)),
          se=sd/sqrt(n))  

########################################################
####2.1数据的清洗/缺失值处理("VIM","mice")
########################################################

#install.packages(c("VIM","mice"))

####缺失值的识别####
is.na(c(1, NA))
A=matrix(c(1,NA,3,NA,2,4),ncol=2)
A
complete.cases(A)
A[complete.cases(A),]

head(is.na(Loan$annual_inc),5)
sum(is.na(Loan$annual_inc)) 
complete.cases(Loan)
Loan[complete.cases(Loan),1:7]

####探索缺失值模式值####
Loan.num=select(Loan,loan_amnt,funded_amnt,funded_amnt_inv,
                installment,annual_inc,dti,total_pymnt)
library(mice)
md.pattern(Loan.num)p

library(VIM)
aggr(Loan.num,prop=FALSE,numbers=TRUE)

####缺失值的删除与填补
data("airquality")
any(is.na(airquality))
aggr(airquality,prop=FALSE,numbers=TRUE) # prop参数表示是否要用比例来表示缺失数据，numbers参数表示是否要显示数字

##个案剔除法
airquality[complete.cases(airquality),]

##成对删除
apply(airquality,2,mean,na.rm=TRUE) #2表示对于列，1的话对于行（如果这个x是个矩阵的话） na.rm决定是否在计算前要将NA值去除

cor(airquality, use = "pair") #cov,cor大体上有"pairwise"和"completion“参数，第一个在计算两个列向量的cov，cor时
#如果有缺失值不会算，如对于"complete“则会先把表里面有NA值得行给删了再计算列与列的corcov



##简单插补（均值插补为例）
mean6=apply(airquality,2,mean,na.rm=TRUE) #2表示对列进行函数操作

air_meanimput=airquality
air_meanimput$col=c("Mean_imputation","notNA")[complete.cases(airquality[,1:2])+1] 
#complete.cases根据向量/矩阵/数据是否有缺失生成一列TRUE,FALSE的逻辑序列，其中TRUE值为1，FALSE值为0。
#通过+1使逻辑序列变成常数序列，其中为FALSE的即原来数据中NA的数值为1，TRUE的为2
air_meanimput
air_meanimput[is.na(air_meanimput$Ozone),"Ozone"]=mean6["Ozone"] 
#一个数据集/矩阵方括号中接受一个逻辑序列和列名，表示按顺序把数据TRUE的列列出来，FALSE的舍去，没写的照常列出
#例如airquality[c(TRUE,FALSE,TRUE,FALSE,TRUE),"Ozone"]就表示把Ozone列第2 4行数据舍弃
air_meanimput[is.na(air_meanimput$Solar.R),"Solar.R"]=mean6["Solar.R"]

##均值插补影响
library(ggplot2)

ggplot(air_meanimput,aes(Ozone,fill=col))+geom_histogram(binwidth=3,position = "identity")
#ggplot用于生成对象，geom_histogram用于生成图层，geom_histogram中数据没有指定则继承自ggplot的aes（）
# position参数的几个值效果dodge	避免重叠，并排放置
# fill	堆叠图形元素并将高度标准为1
# identity	不做任何调整
# jitter	给点添加扰动避免重合
# stack	将图形元素堆叠起来
ggplot(air_meanimput,aes(x=Solar.R,y=Ozone,colour=col))+geom_point(size=4)
#colour=列名，这一列是分组变量，不同的组用不同的颜色表示，例如M,F或者男，女

##回归插补
air_regimput=airquality
air_regimput$col=c("Reg_imputation","notNA")[as.vector(!is.na(airquality["Ozone"]))+1]
#等同于air_regimput$col2=c("Reg_imputation","notNA")[complete.cases(airquality[,1])+1]
fit=lm(Ozone~Temp,data=air_regimput)
pred=predict(fit,newdata = air_regimput[!complete.cases(air_regimput),])
a=which(!complete.cases(air_regimput)) #输出有缺失的行ID
air_regimput$Ozone[a]=as.vector(pred)
##回归插补效果
ggplot(air_regimput,aes(Ozone,fill=col))+geom_histogram(binwidth=3,position = "identity")
ggplot(air_regimput,aes(x=Temp,y=Ozone,colour=col))+geom_point(size=4)

##KNN
# 用K个与目标距离最短的数据加权平均，权重为1/d
install.packages("DMwR")
library(DMwR)
data("airquality")
air_KNN=knnImputation(airquality,k=10,meth="weighAvg") # weights: exp(-dist(k,x)

##knn插补效果
air_KNN$col=c("KNN_imputation","notNA")[complete.cases(airquality[,1:2])+1]
ggplot(air_KNN,aes(Ozone,fill=col))+geom_histogram(alpha=0.5,position = "identity")
ggplot(air_KNN,aes(x=Solar.R,y=Ozone,colour=col))+geom_point(size=4)


##多重插补
library(mice)
imp=mice(airquality,m=5,seed=1,print=FALSE) #5重插补，即生成5个无缺失数据集
# set.seed()用于设定随机数种子，一个特定的种子可以产生一个特定的伪随机序列，这个函数的主要目的
# 是让你的模拟能够可重复出现，因为很多时候我们需要取随机数，但这段代码再跑一次的时候，结果就不一样了
# 如果需要重复出现同样的模拟结果的话，就可以用set.seed()。在调试程序或者做展示的时候，结果的可重复性是很重要的，所以随机数种子也就很有必要。 也可以简单地理解为括号里的数只是一个编号而已，例如set.seed(100)不应将括号里的数字理解成“一百”，而是应该理解成“编号为一零零的随机数发生”，下一次再模拟可以采用二零零（200）或者一一一（111）等不同的编号即可，编号设定基本可以随意。
imp$imp$Ozone #每个插补数据集缺失值位置的数据补齐具体数值
fit=with(imp,lm(Ozone~Wind+Temp+Solar.R))#选择插补模型(回归法),查看fit可以看哪个方法好
pooled=pool(fit)
air_mulimput=complete(imp,action = 1) #action的设置（自查）,action用于选择插补结果,输出的为插补后的结果
##多重插补效果
air_mulimput$col=c("Multip_imputation","notNA")[complete.cases(airquality[,1:2])+1]#用原数据NA的地方标记填补
ggplot(air_mulimput,aes(Ozone,fill=col))+geom_histogram(alpha=0.5,position = "identity")
ggplot(air_mulimput,aes(x=Solar.R,y=Ozone,colour=col))+geom_point(size=4)

boxplot(airquality)

library(DMwR)
iris2=iris[,1:4]
iris
LOF=lofactor(iris2,k=5)
LOF
outlier.LOF=order(LOF,decreasing = T)[1:5] #从大到小排列，输出的为序号非值
LOF[outlier.LOF]
plot(density(LOF),main="Dity of LOF") #density表示概率密度函数，plot可以画出来

# 这是对于airquality数据集的操作
airlof=airquality[complete.cases(airquality),][,1:1]
airLofactor=lofactor(airlof,k=5)
outlier.air=order(airLofactor,decreasing = T)[1:5]
airLofactor[outlier.air]
plot(density(airLofactor))

irisKmean=iris[,1:4]
kmeans.result=kmeans(irisKmean,centers = 3)
# 该kmeans对象具有如下成分Available components:可以通过$符号调出
# [1] "cluster" （显示每个数据各分到哪一簇类 用 1,2,3中的序列表示出来） "centers"（显示三个簇类中心的特征）      "totss"        "withinss"     "tot.withinss" "betweenss"    "size"        
# [8] "iter"         "ifault"   
centers=kmeans.result$centers[kmeans.result$cluster,]#生成每个数据隶属于的聚类中心
distance=sqrt(rowSums((irisKmean-centers)^2))#每个数据与聚类中心的距离,rowSums,colSums用于行列数组的求和/平均
outlier=order(distance,decreasing = T)[1:5]
print(irisKmean[outlier,])
plot(irisKmean[,1:2],col=kmeans.result$cluster,pch="*")#pch=1,2,3...'.''+'为不同标记的符号，col表示color
points(kmeans.result$centers,pch=8,col=1:3,cex=2) #cex参数表示放大缩小倍数，col=1:3表示颜色序列 pch表示图形
points(irisKmean[outlier,c("Sepal.Length","Sepal.Width")],col=4,pch="X")#标记离群点


###########################
###### 异常点的检测########
###########################

####1. 单变量的离群点检测###
set.seed(3147)
x=rnorm(100,0,1)
boxplot.stats(x)
boxplot(x,horizontal = T)

####2. 基于距离的离群点检测
## the definition of testing outlier function
outlier.distest <- function(data = data, r = 5, p = 0.1){ #r为半径，算法计算每一个点r半径内有多少其他点，如果超过p*n则不当做离群点
  out <- data.frame(x=numeric(0),y=numeric(0)) #numeric()生成一个n长度值都为0的向量
  for(i in 1:nrow(data)){
    count <- 0
    for(j in 1:nrow(data)){
      distance <- sqrt(sum((data[i,] - data[j,])^2))#计算两个数据点的距离
      if((i != j) & (distance <= r)){
        count <- count + 1
        if(count >= p * nrow(data)){
          break
        }
      }
    }
    if(count < p*nrow(data)){
      out <- rbind(out,data[i,])
    }
  }
  return(out)
}

set.seed(124)
dat1 <- data.frame(x=rnorm(100,0,0.5),y=rnorm(100,0,0.5))
dat2 <- data.frame(x=rnorm(3,4,2),y=rnorm(3,4,2))
dat <- rbind(dat1,dat2)
plot(dat)

m <- outlier.distest(dat,r=4)
m

library(ggplot2)
ggplot() + geom_point(data = dat,aes(x,y)) + geom_point(data=m,aes(x,y),color="red")

####2.LOF算法
library(DMwR)
iris2 <- iris[,1:4]
LOF <- lofactor(iris2,k=5) 
LOF
outlier.LOF <- order(LOF,decreasing = T)[1:5] #输出LOF值5个最大的id作为异常 
LOF[outlier.LOF]  #显示outlier的值
plot(density(LOF),main="Density of LOF")

####3.Kmeans
irisKmean <- iris[,1:4]
kmeans.result <- kmeans(irisKmean,centers = 3)
#查看中心点
kmeans.result$centers  #效果等同于kmeans.result[["centers"]] 可以在右边环境里面把kmeans结果点开来以后选择centers选项
#查看分类情况
kmeans.result$cluster
#根据每个点的分类记录其对应（属于）的聚类中心点
centers <- kmeans.result$centers[kmeans.result$cluster,]  
#计算每个点到所属类别中心点的距离
distance <- sqrt(rowSums((irisKmean-centers)^2))
outliner <- order(distance,decreasing = T)[1:5]
print(irisKmean[outliner,]) 
#然后我们将离群点打印出来 
#首先我们先按照Sepal.Length和Sepal.Width 来绘制所有的散点,
#按照聚类区分颜色
plot(irisKmean[,1:2],col=kmeans.result$cluster,pch="*") 
#打印聚类的中心质心
points(kmeans.result$centers,pch=8,col=1:3,cex=2) 
#这里col还用col=kmeans.result$cluster 赋值的话全为黑色，原因未知 
#打印离群点
points(irisKmean[outliner,c("Sepal.Length","Sepal.Width")],col=4,pch="X")

##########################################################################
###数据变换###############################################################
##########################################################################


#install.packages("caret")
#install.packages("e1071")
library(caret)
library(e1071)
library(dplyr)

Loan=read.csv("C:/Users/yecha/Documents/Lendingclub/LoanStats3a.csv")
head(Loan)

#注意preProcess接受的x必须为数据集或者矩阵，不能用data[,2]或者data$column表示，需要用dplyr的select函数，结果还是个数据集
trans=preProcess(select(Loan,loan_amnt),method = c("range")) #range转换数据到[0,1],preProcess为caret中的包，method为一个字符串型向量
#preProcess数每次操作都估计所需要的参数，并且由predict.preProcess 应用于指定的数据集。用法为predata=preProcess(data,method=...) predict(predata,data)
transtransformed=predict(trans,select(Loan,loan_amnt)) 
head(transformed)

##做标准化变换
transformed=predict(preProcess(select(Loan,loan_amnt)),select(Loan,loan_amnt)) #preProcess 的method默认为c("center", "scale"),
head(transformed)

##box-cox变换
hist(Loan$annual_inc)
summary(Loan$annual_inc)
quantile(Loan$annual_inc,na.rm=T,probs=seq(0.75,1,0.025))#na.rm表示跳过na,probs为一个在0-1内的向量表示概率，seq用于生成vector
Loan.anin=Loan$annual_inc[-which(Loan$annual_inc>400000)]
hist(Loan.anin)
bc=BoxCoxTrans(Loan$annual_inc,na.rm = TRUE)
bc
anntrans=predict(bc,Loan$annual_inc)  #box-cox变换后的数据

par(mfrow=c(1,2))
hist(Loan.anin,xlab = "Annual income",main = "Histogram: Original data")
hist(anntrans,xlab = "Log of annual income"
     ,main = "Histogram: Logrithm transformed data")




