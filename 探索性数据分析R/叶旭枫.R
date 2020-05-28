library(mvtnorm)
v1=c(1,0.5)
v2=c(0.5,1)
cov1=cbind(v1,v2)
x = rmvnorm(100,c(0,0),cov1)
list=runif(100,0,100)


library(mvtnorm)
cov1 = matrix(data = c(1,0.5,0.5,1),ncol = 2)
x = rmvnorm(100,c(0,0),cov1)
xmacr=x
randlist=runif(100)
for (i in 1:100)
  if (randlist[i]<0.3){
    xmacr[i,1]="NA"
  }
