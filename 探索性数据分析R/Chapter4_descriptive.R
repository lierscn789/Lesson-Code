#####Chapter5 数据的展示####################
require(ggplot2)

####Section 1. ggplot2基本要素
data(diamonds)
str(diamonds)

set.seed(42)
small=diamonds[sample(nrow(diamonds), 1000), ] #sample(x, size, replace = FALSE, prob = NULL)
head(small)

##1.数据（Data）和映射（Mapping)
##以克拉(carat)数为X轴变量，价格(price)为Y轴变量
p = ggplot(data = small, mapping = aes(x = carat, y = price))
p+geom_point()
##进一步,将切工（cut）映射到形状属性
p = ggplot(data=small, mapping=aes(x=carat, y=price, color=cut)) #color可以根据有序变量进行由深到浅的颜色分类，如果换成shape会提示对于有序变量用shape分类不建议
p+geom_point()
##再进一步, 将钻石的颜色（color）映射颜色属性：
p = ggplot(data=small, mapping=aes(x=carat, y=price, shape=cut, colour=color))
p+geom_point()

##将Y轴坐标进行log10变换，再自己定义颜色为彩虹,这两部分称为标尺，不改变数据，改变显示方式
ggplot(small)+geom_point(aes(x=carat, y=price, shape=cut, colour=color))+
  scale_y_log10()+scale_colour_manual(values=rainbow(7))

##统计变换：加一条回归线 
ggplot(small, aes(x=carat, y=price))+geom_point()+
  scale_y_log10()+stat_smooth(method = "auto")

##坐标轴翻转
p=ggplot(small)+geom_bar(aes(x=cut,fill=clarity))
p
p+coord_polar(theta = "y") #分层饼图。用一段一段来表示组成
p+coord_polar() #分层风玫瑰图：用一圈一圈来表示扇形内部组成
p+coord_flip()
##转换极坐标
p=ggplot(small)+geom_bar(aes(x=factor(1), fill=cut))
p
p+coord_polar(theta="y") #theta参数选择"x"或"y"表示作为角度变量的,如果不加theta=“y“则生成风玫瑰图

##分面：按切工分组，分别作图
p=ggplot(small, aes(x=carat, y=price))+geom_point(aes(colour=cut))+ scale_y_log10() 
p
p+ facet_wrap(~cut)+stat_smooth() #根据cut分为5类，理论上也可以分为某类和非某类两类（当变量比较多，并且某一种比较特殊时）
#facet_wrap（~变量名）表示根据某变量分组
##
p=ggplot(small, aes(x=cut, y=price,colour=color))+geom_boxplot()
p+ggtitle("Price Vs. Cut")

#########################################################
####Section 2. 单变量数据的展示

setwd("C:/Users/yecha/Documents/Lendingclub/")
data=read.csv("LoanStats3a.csv",header=T, sep=",")

##1. 条形图
ggplot(data, aes(x=grade))+geom_bar()
ggplot(data, aes(x=grade,fill=grade))+geom_bar()

##2.饼图
ggplot(data, aes(x=factor(1),fill=grade))+geom_bar()+coord_polar(theta = "y") #factor函数用于将字符类变量变成分类变量
ggplot(data, aes(x=grade,fill=grade))+geom_bar()+coord_polar()

##3.直方图
ggplot(small)+geom_histogram(aes(x=price))
##4. 密度图
ggplot(small)+geom_density(aes(x=price))
ggplot(small,aes(x=price))+geom_histogram(aes(y=..density..))+geom_density(colour="blue")
##5. 箱线图
ggplot(small)+geom_boxplot(aes(x=factor(1),y=price))

##加入分类变量的制图
##6. 条形图+分类变量
ggplot(small,aes(x=cut,fill=color))+geom_bar()
ggplot(small,aes(x=cut,fill=color))+geom_bar(position="fill")
ggplot(small,aes(x=cut,fill=color))+geom_bar(position = "dodge")
ggplot(small,aes(x=cut,fill=color))+geom_bar()+facet_wrap(~color)

##定量变量+分类变量
##7. 直方图+分类变量
ggplot(small)+geom_histogram(aes(x=price, fill=cut))
ggplot(small)+geom_histogram(aes(x=price, fill=cut), position="dodge")
ggplot(small)+geom_histogram(aes(x=price, fill=cut), position="fill")
ggplot(small,aes(x=price,fill=cut))+geom_histogram()+facet_wrap(~cut)

##8. cleveland点图/简单条形统计图
ggplot(small,aes(x=cut,y=price))+geom_point()
ggplot(small,aes(x=cut,y=price))+geom_bar(stat = "identity")


####Section 3. 多变量数据的展示
setwd("C:/Users/yecha/Documents/Lendingclub/")
Dev=read.csv("keyindicators.csv",header=TRUE,sep = ",",encoding = "UTF-8")

str(Dev) #压缩展示R对象的结构

Dev$Income.Group=factor(Dev$Income.Group,order=T,levels = c("Low income",
    "Lower middle income","Upper middle income","High income: OECD","High income: nonOECD"))

Dev1=subset(Dev,select=c(1:4,8,9,13,14));   dim(Dev1) #subset用于生成向量，矩阵，数据集的子集，select用向量或者数字表示去掉的列
Dev1=Dev1[complete.cases(Dev1),];    dim(Dev1) #dim返回括号里的维度，对于数据集返回行数+列数

##1. 国家国民收入是否对国民寿命有影响？如果有影响，对女性和男性的影响是否相同？
ggplot(Dev1, aes(x=aGNI))+geom_point(aes(y=life_exp_m,colour=I("blue")))+
  geom_point(aes(y=life_exp_f,colour=I("red")))+
  labs(x="aGNI",y = "Lifetime expected")+geom_smooth(aes(y=life_exp_m))+geom_smooth(aes(y=life_exp_f))+#x="aGNI"在ggplot里面已经有了，就不用在回归线图层里再说
  scale_color_manual(name="Sex",values=c("blue","red"),labels=c("Male","Female"))

##2. 绘制国家国民收入与男性国民寿命的二维变量等高线图
p=ggplot(Dev1,aes(x=log(aGNI),y=life_exp_m))
p+geom_point()+stat_density2d()

##3. 气泡图、散点图阵
p=ggplot(Dev1,aes(x=log(aGNI),y=life_exp_f,size=population))
p+geom_point(colour="lightblue",alpha = .8)+scale_size_area(max_size = 25)

Dev2=data.frame(log(Dev1$aGNI),Dev1$life_exp_f,Dev1$population) #data.frame()函数可以生成数据集
names(Dev2)=c("log(aGNI)","life_exp_f","population") #对数据集列名进行命名
pairs(Dev2) #用于生成图像矩阵

quantile(Dev2$population,seq(0,1,0.1))#seq接受一个向量，或者用seq函数生成的向量，seq三个参数分别表示from to by
#0%    10%    20%    30%    40%    50%    60%    70%    80%    90%   100% 
#3.0    4.5    6.0    8.0   10.0   15.0   21.0   30.0   48.0   90.5 1351.0 

Dev3=subset(Dev2, population < 100,select = c(1,2,3))
pairs(Dev3)

##4. 请将数据进行变换使国家国民收入与国民寿命呈线性关系，并在其上分别添加女性和
##男性的回归线。
ggplot(Dev1, aes(x=log(aGNI)))+geom_point(aes(y=life_exp_m,colour=I("blue")))+
  stat_smooth(aes(y=life_exp_m),method=lm,colour=I("blue"))+
  geom_point(aes(y=life_exp_f,colour=I("red")))+
  stat_smooth(aes(y=life_exp_f),method=lm,colour=I("red"))+
  labs(x="log(aGNI)",y = "Lifetime expected")+
  scale_color_manual(name="Sex",values=c("blue","red"),labels=c("Male","Female"))

##5. 请分收入水平展示国家国民收入与国民寿命的关系。
ggplot(Dev1, aes(x=log(aGNI)))+geom_point(aes(y=life_exp_m,colour=I("blue")))+
  geom_point(aes(y=life_exp_f,colour=I("red")))+
  facet_wrap(~Income.Group)+
  labs(x="log(aGNI)",y = "Lifetime expected")+
  scale_color_manual(name="Sex",values=c("blue","red"),labels=c("Male","Female"))


##6. 请作图比较男性和女性寿命的分布曲线。
ggplot(Dev1)+geom_density(aes(x=life_exp_m,colour=I("blue")))+
  geom_density(aes(x=life_exp_f,colour=I("red")))+
  labs(x="Life expected",y = "density")+
  scale_color_manual(name="Sex",values=c("blue","red"),labels=c("Male","Female"))

##7. 请作图比较男性和女性寿命的均值以及分布。
boxplot(Dev1$life_exp_m,Dev1$life_exp_f,names=c("Male","Female"))

##8. 请作图展示各变量之间的关系。
pairs(Dev1[,4:8],main="Scatter plot matrix")

library(corrplot)
cormatrix=cor(Dev1[,4:8])
corrplot(cormatrix,main="Correlation matrix")

##9. 请作图展示国家间的相似度。
D.stnd=scale(Dev1[,4:8])
dist.euc=dist(D.stnd,method = "euclidean")
dist.euc=as.matrix(dist.euc)
heatmap(dist.euc,main="Heatmap")



