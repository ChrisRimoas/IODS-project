## Task 2

setwd("D:/New folder/OneDrive for Business 1/Git/IODS/IODS-project/data")

alc <- read.table(file = "alc.txt",
                           header = TRUE,
                           dec = ".")
# Libraries
library(tidyr)
library(dplyr)
library(ggplot2)
library(GGally)

# Structure
str(alc)
names(alc)

## Task 3

# Hypotheses

#1.[address] The probability of higher alcohol consumption is higher for students living in rural areas;
#2.[free time] The probability of higher alcohol consumption is higher for students with more free time;
#3.[sex] The probability of higher alcohol consumption is higher for male students;
#4.[failures] The probability of higher alcohol consumption is higher for students with more failures.

## Task 4

# Relationships
par(mfrow = c(2, 2), mar = c(5, 5, 2, 2), cex.lab = 1.5)
boxplot(alc$alc_use ~ address,
        varwidth = TRUE, 
        data = alc,
        xlab     = "address",
        ylab     = "alcohol use")

boxplot(alc$alc_use ~ freetime,
        varwidth = TRUE, 
        data = alc,
        xlab     = "freetime",
        ylab     = "alcohol use")

boxplot(alc$alc_use ~ sex,
        varwidth = TRUE, 
        data = alc,
        xlab     = "sex",
        ylab     = "alcohol use")

boxplot(alc$alc_use ~ failures,
        varwidth = TRUE, 
        data = alc,
        xlab     = "failures",
        ylab     = "alcohol use")

#On average students living in rural areas drink more than students living in urban areas.
#Alcohol use seems to increase with the amount of free time.
#Male students drink on average more than female students.
#Students who failed at least once seem more likely to drink more alcohol than those who have never failed,
#but the amount of failures does not seem to matter for alcohol consumption.

## Task 5

# Fit the model
m1 <- glm(high_use ~ address + freetime + failures + sex, data = alc, family = "binomial")
summary(m1)
drop1(m1, test="Chi")
# Students living in urban areas tend to have lower probability of high alcohol consumption, but as the significance
#is borderline we drop this covariate.
# The probability of high alcohol consumption is higher for students with more freetime and failures, as well as for
#guys compared to girls.

m2 <- glm(high_use ~ freetime + failures + sex, data = alc, family = "binomial")
summary(m2)

# Probability of high consumption for females 
#       exp(-2.1678 + 0.2509*freetime_i + 0.4696*failures_i)
# pi_i = ----------------------------------------------------
#       1 + exp(-2.1678 + 0.2509*freetime_i + 0.4696*failures_i)


# Probability of high consumption for males 
#       exp(-2.1678 + 0.7333 + 0.2509*freetime_i + 0.4696*failures_i)
# pi_i = ----------------------------------------------------
#       1 + exp(-2.1678 + 0.2509*freetime_i + 0.4696*failures_i)

# odds ratios (OR)
OR<- coef(m2) %>% exp
# confidence intervals (CI)
CI<-confint(m2) %>%exp
# odds ratios with their confidence intervals
cbind(OR, CI)
#Odds are all higher than 1, meaning that all covariates are positively associated with high alcohol consumption.

## Task 6

# Predictive power of model

probabilities <- predict(m2, type = "response")
alc <- mutate(alc, probability = probabilities)
alc <- mutate(alc, prediction=probability>0.5)

# tabulate the target variable versus the predictions
table(high_use = alc$high_use, prediction = alc$prediction)
table(high_use = alc$high_use, prediction = alc$prediction)%>%prop.table()%>%addmargins()
# The practice data (actual values) comprised 259 FALSE (low consumption) and 9 TRUE (high consumption), whereas
# the test (prediction) comprised 100 FALSE and 14 TRUE values.

# loss function (mean prediction error)
loss_func <- function(class, prob) {
  n_wrong <- abs(class - prob) > 0.5
  mean(n_wrong)
}

# average number of wrong predictions
loss_func(class = alc$high_use, prob = alc$probability)
# 28% of individuals are inaccurately classified by the model (m2)


## Bonus

# K-fold cross-validation
library(boot)
cv1 <- cv.glm(data = alc, cost = loss_func, glmfit = m1, K = 10)
cv1$delta[1]
# My model does not provide a smaller prediction error than DataCamp model.


m3 <- glm(high_use ~sex*absences, data = alc, family = "binomial")
summary(m3)
cv3 <- cv.glm(data = alc, cost = loss_func, glmfit = m3, K = 10)
cv3$delta[1]

# A model with an interaction between absences and sex provides smaller prediction error.

