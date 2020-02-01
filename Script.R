
#Load the .Rdata
library(car)
load("~/OneDrive - MNSCU/myGithub/Statistics/Regression_models/Multiple_Linear_Regression/Multiple-Linear-Regression/mult.Rdata")
load("~/OneDrive - MNSCU/myGithub/Statistics/Regression_models/Multiple_Linear_Regression/Multiple-Linear-Regression/Regression.Rdata")


# Data

#The data for these sales comes from the official public records of home sales in the King County area, Washington State. The data set contains 21,606 homes that sold between May 2014 and May 2015. 
#Load the train and test data sets. The description of all variables is in the data section.

KingTest = read.csv(file = "King County Homes (test).csv")
King = read.csv("King County Homes (train).csv")

str(King)
summary(King)


#Explore factor and ordinal variables

#Factor variables: 
#waterfront (dummy), renovated(dummy), zipcode
#Ordinal variables:
#view (0-4), condition (1-5), grade (1-13), 
King$waterfront = as.factor(King$waterfront)
King$renovated= as.factor(King$renovated)
King$zipcode = as.factor(King$zipcode)
summary(King)


#First, we are going to fit a base model and discuss any deficiencies.

names(King)
#remove ID variable to only have y and x's df
King_clean = King[,-1]

#Fit a full model:
lm1.king = lm(price~., data = King_clean)
#summary(lm1.king)


{par(mfrow=c(2,2))
boxplot(price~waterfront, data = King_clean, main = "Price by Waterfront")
boxplot(price~renovated, data = King_clean, main = "Price by Renovated")
boxplot(price~zipcode, data = King_clean, main = "Price by Zipcode")
}

names(King_clean)

{
par(mfrow=c(2,2))
plot(lm1.king)  
}

{
y = King_clean$price
yhat = predict(lm1.king, data = King_clean)
ehat = resid(lm1.king)
ehat = y - yhat
}

{
par(mfrow=c(1,2))
trendscat(y,yhat, xlab = "Actual Price", ylab = "Predicted Prince")
abline(0,1, lwd = 2, col = "red")
trendscat(y, ehat, xlab = "Predicted Price", ylab = "Residuals")
abline(h = 0, lwd = 2, col = "red")
}

#Backward Elimination
{back.king = step(lm1.king, direction = "backward")

anova(back.king)

back.king$anova
}

## Mixed model selection
{
mixed.king = step(lm1.king)
anova(mixed.king)
mixed.king$anova
}

#Final model: mixed.king 

VIF(mixed.king)

## Using cross-validation methods to estimate the prediction error of this model using split-sample, k-fold, and the .632 bootstrap approaches

### Split-sample approach
{
n = nrow(King_clean)
CV = sample(c("Train", "Valid"), size = n, replace = T, prob = c(.70, .30))
}
king.lm2 = lm(price~., data = King_clean[CV == "Train",])
#summary(king.lm2)


#Mixed model stepwise: use the final model above
{mixed.king2 = step(king.lm2)
mixed.king2$anova
}
{  
PredAcc = function(y, ypred){
  RMSEP = sqrt(mean((y-ypred)^2))
  MAE = mean(abs(y-ypred))
  MAPE = mean(abs(y-ypred)/y)*100
  cat("RMSEP\n")
  cat("================\n")
  cat(RMSEP, "\n\n")
  cat("MAE\n")
  cat("================\n")
  cat(MAE, "\n\n")
  cat("MAPE\n")
  cat("================\n")
  cat(MAPE, "\n\n")
  return(data.frame(RMSEP = RMSEP, MAE = MAE, MAPE = MAPE))
  
}

myBC = function(y) {
  require(car)
  BCtran(y)
  results = powerTransform(y)
  summary(results)
}

kfold.MLR.log = function(fit,k=10) {
  sum.sqerr = rep(0,k)
  sum.abserr = rep(0,k)
  sum.pererr = rep(0,k)
  y = fit$model[,1]
  y = exp(y)
  x = fit$model[,-1]
  data = fit$model
  n = nrow(data)
  folds = sample(1:k,nrow(data),replace=T)
  for (i in 1:k) {
    fit2 <- lm(formula(fit),data=data[folds!=i,])
    ypred = predict(fit2,newdata=data[folds==i,])
    sum.sqerr[i] = sum((y[folds==i]-ypred)^2)
    sum.abserr[i] = sum(abs(y[folds==i]-ypred))
    sum.pererr[i] = sum(abs(y[folds==i]-ypred)/y[folds==i])
  }
  cv = return(data.frame(RMSEP=sqrt(sum(sum.sqerr)/n),
                         MAE=sum(sum.abserr)/n,
                         MAPE=sum(sum.pererr)/n))
}



bootlog.cv = function(fit,B=100,data=fit$model) {
  yt=fit$fitted.values+fit$residuals
  yact = exp(yt)
  yhat = exp(fit$fitted.values)
  resids = yact - yhat
  ASR=mean(resids^2)
  AAR=mean(abs(resids))
  APE=mean(abs(resids)/yact)
  boot.sqerr=rep(0,B)
  boot.abserr=rep(0,B)
  boot.perr=rep(0,B)
  y = fit$model[,1]
  x = fit$model[,-1]
  n = nrow(data)
  for (i in 1:B) {
    sam=sample(1:n,n,replace=T)
    samind=sort(unique(sam))
    temp=lm(formula(fit),data=data[sam,])
    ytp=predict(temp,newdata=data[-samind,])
    ypred = exp(ytp)
    boot.sqerr[i]=mean((exp(y[-samind])-ypred)^2)
    boot.abserr[i]=mean(abs(exp(y[-samind])-ypred))
    boot.perr[i]=mean(abs(exp(y[-samind])-ypred)/exp(y[-samind]))
  }
  ASRo=mean(boot.sqerr)
  AARo=mean(boot.abserr)
  APEo=mean(boot.perr)
  OPsq=.632*(ASRo-ASR)
  OPab=.632*(AARo-AAR)
  OPpe=.632*(APEo-APE)
  RMSEP=sqrt(ASR+OPsq)
  MAEP=AAR+OPab
  MAPEP=(APE+OPpe)*100
  cat("RMSEP\n")
  cat("===============\n")
  cat(RMSEP,"\n\n")
  cat("MAE\n")
  cat("===============\n")
  cat(MAEP,"\n\n")
  cat("MAPE\n")
  cat("===============\n")
  cat(MAPEP,"\n\n")
  return(data.frame(RMSEP=RMSEP,MAE=MAEP,MAPE=MAPEP))  
}
}
{
y = King_clean$price[CV == "Valid"]
ypred = predict(mixed.king2, newdata = King_clean[CV=="Valid",])
results = PredAcc(y,ypred)
}

#### K-fold 
{
king.lm1 = lm(price~., data = King_clean)
mixed.king1 = step(king.lm1)

kfold.results.full = kfold.MLR(king.lm1, k=10)
kfold.results.full

kfold.results.step = kfold.MLR(mixed.king1, k=10)
kfold.results.step
}
#RMSE is better for the step model than for the full model.

#### .632 Bootstrap

{
king.lm1 = lm(price~., data = King_clean)
mixed.king1 = step(king.lm1)

boot.results.full = bootols.cv(king.lm1, B=100)
boot.results.full

boot.results.step = bootols.cv(mixed.king1, B=100)
boot.results.step
}
#boot.results.step had error rates smaller MAE (97719.86) and MAPE (19.93%). RMSE (164952) was a bit higher than that of the full model (163795.6).

# Applying transformations to the model

{
king.lm1 = lm(price~., data = King_clean)
summary(king.lm1)
}

### Check for skewness:
pairs.plus2(King_clean[,c(1:6,8:14,17:20)])


### Transforming Home Price
#Statplot() function provided in the .Rdata file can check for the distribution of the specified predictor or response.
Statplot(King_clean$price)
Statplot(log(King_clean$price))

{
function(y) {
  require(car)
  BCtran(y)
  results = powerTransform(y)
  summary(results)
}
}

myBC(King_clean$price)
summary(King_clean)

myBC(King_clean$bedrooms+1)
#labmda = 0.3 for bedrooms
myBC(King_clean$bathrooms+1)
# lambda = 0.4 for bathrooms
myBC(King_clean$sqft_living)
#log(sqft_living)
myBC(King_clean$sqft_lot)
#lambda = -.20
myBC(King_clean$floors+1)
#lambda = -.40
myBC(King_clean$view+1)
#lambda = -2
myBC(King_clean$condition)
#lambda = -.3
myBC(King_clean$grade)
#lambda = -.3
myBC(King_clean$sqft_above)
#lambda = -.2
myBC(King_clean$yr_built)
#lambda = 2
myBC(King_clean$yr_renovated+1)
#lambda = -2
myBC(King_clean$lat)
#lambda = 2


#Copy of the training set
{
King_Trans = King_clean[,-12] #removing the sqft_basement
King_Trans$bedrooms = yjPower(King_Trans$bedrooms, 0.30)
King_Trans$bathrooms = yjPower(King_Trans$bathrooms, 0.40)
King_Trans$sqft_living = bcPower(King_Trans$sqft_living, 0)
King_Trans$sqft_lot = bcPower(King_Trans$sqft_lot, -0.20)
King_Trans$floors = yjPower(King_Trans$floors, -.40)
King_Trans$view = yjPower(King_Trans$view, -2)
#King_Trans$condition = bcPower(King_Trans$condition, -0.30)
King_Trans$grade = bcPower(King_Trans$grade, -0.30)
King_Trans$sqft_above = bcPower(King_Trans$sqft_above, -0.20)
#King_Trans$yr_built = bcPower(King_Trans$yr_built, 2)
#King_Trans$yr_renovated = yjPower(King_Trans$yr_renovated, 2)
#King_Trans$lat = bcPower(King_Trans$lat, 2)
}
{trans.lm1 = lm(price~., data = King_Trans)
par(mfrow=c(2,2))
plot(trans.lm1)
}
{
King_Trans$price =  log(King_Trans$price)
Statplot(King_Trans$price)
}

{loghp.trans.lm1 = lm(price~., data = King_Trans)
par(mfrow=c(2,2))
plot(loghp.trans.lm1)
}

VIF(loghp.trans.lm1)


names(King_Trans)
loghp.trans.lm2 = lm(price~., data = King_Trans[,-13])
par(mfrow=c(2,2))
#plot(loghp.trans.lm2)
#summary(trans.lm3)
vif(loghp.trans.lm2)


str(King_Trans$zipcode)
table(King_Trans$zipcode)

#Predictive performance of loghp.trans.lm2


loghp.trans.lm2.step = step(loghp.trans.lm2)
loghp.trans.lm2.step$anova

{y=King_clean$price
yloghat = fitted(loghp.trans.lm2.step)
yexp = exp(yloghat)
RMSElog = sqrt(mean((y-yexp)^2))
MAPElog = mean(abs(y-yexp)/y)
MAElog = mean(abs(y-yexp))

ypred = fitted(trans.lm1)
RMSEorig = sqrt(mean((y-ypred)^2))
MAPEorig = mean(abs(y-ypred)/y)
MAEorig = mean(abs(y-ypred))
}
{
RMSElog 
RMSEorig
MAPElog
MAPEorig #these need to be times by 100 to be in %
MAElog
MAEorig
}
### Cross validate using split-sample approach ###
{
CV = sample(c("Train", "Valid"), size = n, replace = T, prob = c(0.70 , 0.30))
cv.loghp.trans.lm2.step = lm(price~., data = King_Trans[CV == "Train",-13])
cv.loghp.trans.lm2.step = step(cv.loghp.trans.lm2.step)
cv.loghp.trans.lm2.step$anova
}
summary(cv.loghp.trans.lm2.step)
vif(cv.loghp.trans.lm2.step)

{
y = King_Trans$price[CV == "Valid"]
y = exp(y)
ypred = predict(cv.loghp.trans.lm2.step, newdata = King_Trans[CV=="Valid",])
results = PredAcc(y,ypred)
}

###Cross validate using k-fold ###

kfold.MLR.log(loghp.trans.lm2.step, k=10)

###Cross validate using .632 bootstrat approach ###

bootlog.cv(loghp.trans.lm2.step, B=100)

#The best predictions had the .632 bootstrap of the transformed model (logged response with predictors transformed the way it was described above).
#The final model from problem 1 where we did not do any modifications or acocunt for defficiencies:
#Boot strap:
#
# RMSE = 164,952
# MAE = 97,719.85
# MAPE = 19.93%
#
# The final model after transformations
# Boot strap:
# RMSE = 135,906.9
# MAE = 74893.33
# MAPE = 13.7%

#Review the model
anova(loghp.trans.lm2.step)


#The following predictors were removed
loghp.trans.lm2.step$anova


#The model with transformations and predictors that were removed in the stepwise selection (and sqft_basement and renovated removed because of multicollinearity) predicted the best. 

# Let's predict using the test set right now. 

#First, we need to apply the same chages and transformations we did to the training set to the test set.

KingTest$waterfront = as.factor(KingTest$waterfront)
KingTest$renovated= as.factor(KingTest$renovated)
KingTest$zipcode = as.factor(KingTest$zipcode)


#Do the same transformations to the test set as we've done to the training set:

names(KingTest)
#Transformations:

#Copy of the training set

{
King_Test = KingTest[,-1] #removin ID
King_Test = KingTest[,-12] #removing the sqft_basement
King_Test$bedrooms = yjPower(King_Test$bedrooms, 0.30)
King_Test$bathrooms = yjPower(King_Test$bathrooms, 0.40)
King_Test$sqft_living = bcPower(King_Test$sqft_living, 0)
King_Test$sqft_lot = bcPower(King_Test$sqft_lot, -0.20)
King_Test$floors = yjPower(King_Test$floors, -.40)
King_Test$view = yjPower(King_Test$view, -2)
#King_Trans$condition = bcPower(King_Trans$condition, -0.30)
King_Test$grade = bcPower(King_Test$grade, -0.30)
King_Test$sqft_above = bcPower(King_Test$sqft_above, -0.20)
#King_Trans$yr_built = bcPower(King_Trans$yr_built, 2)
#King_Test$yr_renovated = yjPower(King_Test$yr_renovated, 2)
#King_Trans$lat = bcPower(King_Trans$lat, 2)
}


# <b>Predict and Write to .csv</b>
mypred = predict(loghp.trans.lm2.step,newdata=King_Test)
#The response is logged. Make sure to convert it back to USD!
mypred.dollars = exp(mypred)
#Save it as a data frame that also contains ID of each individual home
submission = data.frame(ID=KingTest$ID,ypred=mypred.dollars)
#Write to .csv file
write.csv(submission,file="Predictions.csv")



