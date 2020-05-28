#####Chapter Logistic regression#######
library(ROCR)
library(ggplot2)

#####Example1: Death Penalty#######
###汇总数据结构############
DP<-read.table("C:/Users/yecha/Downloads/deathpenalty.txt",header = TRUE)
DP
##1)建立拟合方程，做方差分析
DP.form="cbind(DeathY,DeathN)~Aggrav+Race"
DPglm.out = glm(DP.form, family=binomial(logit), data=DP)
summary(DPglm.out)
pre=predict(DPglm.out,type='response')
##2）背叛死刑的概率拟合值图
plot(DPglm.out$fitted[DP$Race=="White"],type="b",pch=19,xlab="Aggravation",ylab="Probability of death sentence")
points(DPglm.out$fitted[DP$Race=="Black"],type="b",pch=24)
legend(1,1.0,c("White","Black"),pch=c(19,24))
###4)ROC曲线
data=data.frame(prob=pre,DeathY=DP$DeathY,DeathN=DP$DeathN)
data=data[order(data$prob),]
n=nrow(data)
tpr=fpr=rep(0,n)
for (i in 1:n){
  threshold=data$prob[i]
  tp=sum(data$DeathY[data$prob>=threshold])
  fp=sum(data$DeathN[data$prob>=threshold])
  tpr[i]=tp/sum(data$DeathY)  #真正率
  fpr[i]=fp/sum(data$DeathN)   #假正率
}
fpr
tpr
plot(c(1,fpr,0),c(1,tpr,0),type='l',xlim=c(0,1),ylim = c(0,1),xlab="FPR",ylab="TPR")
abline(a=0,b=1)


#####Example1: Death Penalty#######
###个案数据结构############
dpen <- read.csv("C:/Users/yecha/Downloads/deathpenaltyind.csv",header = TRUE)
head(dpen)
tail(dpen)
##1)建立拟合方程，做方差分析
m1=glm(Death~VRace+Agg,family=binomial(logit),data=dpen)
m1
summary(m1)
anova(m1,test="Chisq")
##2)统计推断
## calculating logits
exp(m1$coef[2])
exp(m1$coef[3])
##3）背叛死刑的概率拟合值图
## plotting probability of getting death penalty as a function of aggravation
## separately for black (in black) and white (in red) victim
plot(dpen$Agg[dpen$VRace==1],m1$fitted[dpen$VRace==1],type="b",pch=19,xlab="Aggravation",ylab="Probability of death sentence")
points(dpen$Agg[dpen$VRace==0],m1$fitted[dpen$VRace==0],type="b",pch=24)
legend(1,1.0,c("White","Black"),pch=c(19,24))
###4)ROC曲线
pred <- prediction( m1$fitted, dpen$Death )
perf <- performance( pred, "tpr", "fpr" )
plot( perf)
abline(0,1)

##用“pROC”画ROC曲线并确定最优阈值####
library(pROC)
pre=predict(m1,type='response')
DP.roc <- roc(dpen$Death,pre)
plot(DP.roc, print.auc=TRUE, auc.polygon=TRUE, grid=c(0.1, 0.2),
     grid.col=c("green", "red"), max.auc.polygon=TRUE,
     auc.polygon.col="skyblue", print.thres=TRUE)


#####Example2: Donner party#######
Donner<-read.table("donner.txt",header = TRUE)
##（1）性别与是否活下来的列联表
xtabs(~Gender+Surv,data=Donner)
attach(Donner)
##（2）直方图
par(mfrow=c(2,1))
hist(Age[Surv==0],breaks = seq(10,70,10),freq=FALSE,main="死亡组年龄直方图",xlab = "年龄")
lines(density(Age[Surv==0]))
hist(Age[Surv==1],breaks = seq(10,70,10),freq=FALSE,main="生存组年龄直方图",xlab = "年龄")
lines(density(Age[Surv==1]))
##(3)拟合方程
DFM.out = glm(Surv~Gender*Age, family=binomial(logit),data = Donner)
summary(DFM.out)
anova(DFM.out)
DRM.out = glm(Surv~Gender+Age, family=binomial(logit),data=Donner)
summary(DRM.out)
anova(DRM.out)
##3）生存的概率拟合值图
## plotting probability of survive as a function of age
## separately for female and male
Agenew=seq(range(Age)[1]-1,range(Age)[2]+1,1)
newdata=matrix(cbind(Agenew,Agenew,rep(0,length(Agenew)),rep(1,length(Agenew))),ncol=2)
newdata=data.frame(Age=newdata[,1],Gender=newdata[,2])
pre=predict(DRM.out,newdata,type = "response")
predata=data.frame(Age=newdata[,1],Gender=newdata[,2],pre=pre)
plot(predata$Age[predata$Gender==1],predata$pre[predata$Gender==1],type="l",lty=2,xlim=c(14,66),ylim=c(0,0.9),xlab="Age",ylab="Probability of Survival")
points(predata$Age[predata$Gender==0],predata$pre[predata$Gender==0],type="l",lty=6)
legend(55,0.85,c("Female","Male"),lty=c(2,24))

##用“pROC”画ROC曲线并确定最优阈值####
library(pROC)
DFM.pre=predict(DFM.out,type='response')
DFM.roc <- roc(Surv,DFM.pre)
plot(DFM.roc, print.auc=TRUE, auc.polygon=TRUE, grid=c(0.1, 0.2),
     grid.col=c("green", "red"), max.auc.polygon=TRUE,
     auc.polygon.col="skyblue", print.thres=TRUE)

DRM.pre=predict(DRM.out,type='response')
DRM.roc <- roc(Surv,DRM.pre)
plot(smooth(DRM.roc), print.auc=TRUE, auc.polygon=TRUE, grid=c(0.1, 0.2),
     grid.col=c("green", "red"), max.auc.polygon=TRUE,
     auc.polygon.col="skyblue", print.thres=TRUE)