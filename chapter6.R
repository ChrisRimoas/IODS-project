setwd("D:/New folder/OneDrive for Business 1/Git/IODS/IODS-project/data")

BPRSL <- read.table(file = "BPRSL.txt",
                    header = TRUE,
                    dec = ".")


RATSL <- read.table(file = "RATSL.txt",
                           header = TRUE,
                           dec = ".")


# libraries
library(ggplot2)
library("lme4")
# Setting categorical variables to factors

BPRSL$treatment <- factor(BPRSL$treatment)
BPRSL$subject <- factor(BPRSL$subject)

RATSL$ID <- factor(RATSL$ID)
RATSL$Group <- factor(RATSL$Group)

str(RATSL)
str(BPRSL)

# Analysis of RATS data acording to chapter 8 from MABS


ggplot(RATSL, aes(x = Time, y = Weight, linetype = ID)) +
  geom_line() +
  scale_linetype_manual(values = rep(1:10, times=4)) +
  facet_grid(. ~ Group, labeller = label_both) +
  theme_bw() +geom_line(aes(color=ID))+
  scale_y_continuous(limits = c(min(RATSL$Weight), max(RATSL$Weight)))

# This graph shows the individual weight of subjects by treatment group.
#The weight seems to generally inrease with time for individuals in every group treatment.
#One individual from each group seems to either have higher or lower weight compared to
#individuals of the same group. From the graph You can notice that their initial weight was already very different 
#compared to other individuals. This shows that individuals' starting weight should be taken into account when
#quantifying the treatment effects.
#There are more individuals in group 1, and they appear to have the lowest weight.  

#Lets see if we can visualize the variability better with standardized data.

RATSL <- RATSL %>%
  group_by(Time) %>%
  mutate(stdweight = (Weight - mean(Weight))/sd(Weight)) %>%
  ungroup()


ggplot(RATSL, aes(x = Time, y = stdweight, linetype = ID)) +
  geom_line() +
  scale_linetype_manual(values = rep(1:10, times=4)) +
  facet_grid(. ~ Group, labeller = label_both) +
  theme_bw() +geom_line(aes(color=ID))+
  scale_y_continuous(limits = c(min(RATSL$stdweight), max(RATSL$stdweight)))

#Shows what we already knew.

#Let's now plot the mean effect of the 3 treatments in time.

n <- RATSL$Time %>% unique() %>% length()

# Summary data with mean and standard error of Weight by Group and Time 
df <- RATSL %>%
  group_by(Group, Time) %>%
  summarise( mean = mean(Weight), se = sd(Weight)/sqrt(n)) %>%
  ungroup()


ggplot(df, aes(x = Time, y = mean, linetype = Group, shape = Group)) +
  geom_line() +
  geom_point(size=3) +
  geom_errorbar(aes(ymin=mean-se, ymax=mean+se, linetype="1"), width=0.3) +
  theme(legend.position = c(0.8,0.8)) + theme_bw() + geom_line(aes(color=Group))+
  scale_y_continuous(name = "mean (Weight) +/- se (Weight)")


#Here we notice that individuals of Group 3 had the lowest weight throughout the treatment. 
#But then again, they had the lowest weights prior to the treatment.
#We can also see that the standard error of the mean was higher for the observations made in group 2, probably because
#of the individual who had a much higher weight.

#Time for a quick and dirty analysis. 
#Let's average the all repeated observations taken from individual, so we "capture" the general effect of time in
#each individual. 

df1 <- RATSL %>%
    group_by(Group, ID) %>%
  summarise( mean=mean(Weight) ) %>%
  ungroup()

#We can visualize the differences between groups directly.
ggplot(df1, aes(x = Group, y = mean))+
geom_boxplot()+
theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())+
stat_summary(fun.y = "mean", geom = "point", shape=23, size=4, fill = "white")+
scale_y_continuous(name = "mean (Weight)")

#Based on this graph, it looks like there's an outlier in group 2. I wouldn't remove it as there are too few variables
#(n=16). I think that the linear mixed model in this scenario would be able to take into account the specific
#variance between individuals.

#Now we fit the linear model
fitRATS <- lm(mean ~ Group, data = df1)
anova(fitRATS)
#From the anova table we see that the group variable (reflecting treatments) significantly affects the weight of
#the rats.

summary(fitRATS)
#From the summary table we see that treatment 3 (group 3) produces the highest weights, whereas treatment 1 (group 1)
#produces the lowest weights. 

# Analysis of BPRS data acording to chapter 9 from MABS

#Let's plot bprs versus the time, ignoring the fact that repeated measurements were done in each individual.

ggplot(BPRSL, aes(x = week, y = bprs, group = subject))+
geom_text(aes(label = treatment))+
scale_y_continuous(name = "bprs")+
theme_bw()+
theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())

#It doesn't look like the treatments differ. To be sure, let's run a quick linear model.

fitBPRS <- lm(bprs ~ week + treatment, data = BPRSL)
anova(fitBPRS)
#No evidence was found to say the treatment had an effect on the bprs. However, the week significantly affected 
#negatively) bprs.
summary(fitBPRS)
#We can see the coeficients for the model. Treatment 2 had a positive effect on bprs, but non significant. 

ggplot(BPRSL, aes(x = week, y = bprs, linetype = subject)) +
  geom_line() +
  scale_linetype_manual(values = rep(1:10, times=4)) +
  facet_grid(. ~ treatment, labeller = label_both) +
  theme_bw() +geom_line(aes(color=subject))+
  scale_y_continuous(limits = c(min(BPRSL$bprs), max(BPRSL$bprs)))

#From this graph we can see there's a large variability between subjects, making it hard to differenciate treatment
#effects. But we can indeed see the effect of week.

#Let's how the week variables correlate from the wide RATS data.
BPRS<-read.table("https://raw.githubusercontent.com/KimmoVehkalahti/MABS/master/Examples/data/BPRS.txt",
                 header=T, sep=" ")
pairs(BPRS[, 3:11], cex = 0.7)

#The weeks strongly correlate with each other.

#Now we fit the linear mixed effect model with individuals as random intercepts, so the model accounts for the
#variability in subjects

mixedBPRS <- lmer(bprs ~ week + treatment + (1 | subject), data = BPRSL, REML = FALSE)
summary(mixedBPRS)

#The fixed effects were the same found by the linear model, but the mixed model would allow for the intercept
#to be correct 20 times (one per individual). Ideally, the data should've been coded in a way that there would be
#40 individuals. Now it thinks that each individual received both treatments, probably imposing some correlation
#between them. but I am no sure.
#The standard error is slightly smaller, so we can still try to improve the model by fitting a random intercept and
#model, so that the slope of each subject can also change according to week.


mixedBPRS1 <- lmer(bprs ~ week + treatment + (week| subject), data = BPRSL, REML = FALSE)
summary(mixedBPRS1)

#Not so much difference. We can compare them by:
anova(mixedBPRS,mixedBPRS1)
#According to the  likelihood ratio test, the random intercept and slope model is better (LRT=7.27, df=2,p=0.03).

#At last, we fit a random intercept and slope model that allows for a treatment � week interaction, so the slope 
#of week will change based on treatment.

mixedBPRS2 <- lmer(bprs ~ week *treatment + (week| subject), data = BPRSL, REML = FALSE)
summary(mixedBPRS2)

#Next we check if the interaction is significant.
drop1(mixedBPRS2, test="Chi")
#The interaction was not significant for predicting pbrs (LRT=3.17,df=1,p=0.07).

#Let's see what the model predicts.
Fitted <- fitted(mixedBPRS2)
BPRSL <- BPRSL %>% mutate(Fitted)


ggplot(BPRSL, aes(x = week, y = bprs, linetype = subject)) +
  geom_line() +
  scale_linetype_manual(values = rep(1:10, times=4)) +
  facet_grid(. ~ treatment, labeller = label_both) +
  theme_bw() +geom_line(aes(color=subject))

ggplot(BPRSL, aes(x = week, y = Fitted, linetype = subject)) +
  geom_line() +
  scale_linetype_manual(values = rep(1:10, times=4)) +
  facet_grid(. ~ treatment, labeller = label_both) +
  theme_bw() +geom_line(aes(color=subject))


#In these graphs we can see the negative effect of week on bprs, and that there's not much difference between
#treatments. The fitted values include random effects, taking into account the variability within individuals across
#the weeks.


