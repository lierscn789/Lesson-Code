#### ******* German Credit Data ******* ####
#### ******* data on 1000 loans ******* ####


## read data and create relevant variables
credit <- read.csv("D:/MyTeaching/SHUFE/Courses/Dataanalysis/Dataanalysis_201920/作业及练习/练习/Chapt_Logistic/germancredit.csv");
str(credit)

credit$Default <- factor(credit$Default);

###重新定义某些变量的分类###########
credit$history = factor(credit$history, levels=c("A30","A31","A32","A33","A34"));
levels(credit$history) = c("good","good","poor","poor","terrible");
credit$foreign <- factor(credit$foreign, levels=c("A201","A202"), labels=c("foreign","german"));
credit$rent <- factor(credit$housing=="A151");
credit$purpose <- factor(credit$purpose, levels=c("A40","A41","A42","A43",
                                                  "A44","A45","A46","A47","A48","A49","A410"));
levels(credit$purpose) <- c("newcar","usedcar",rep("goods/repair",4),"edu",NA,"edu","biz","biz");

## for demonstration, cut the dataset to these variables
credit <- credit[,c("Default","duration","amount","installment","age", "history", 
                    "purpose","foreign","rent")];
