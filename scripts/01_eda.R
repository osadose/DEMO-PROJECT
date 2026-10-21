##### Exploratory Data Analysis #####

# Reading Dataset --------------------------------
bank_data <- read_delim("data/BankMarketing.csv",
                        delim = ";", escape_double = FALSE, trim_ws = TRUE)

#adding index column for future use
bank_data <- cbind(index = 1:nrow(bank_data), bank_data)

# Data Structure ---------------------------------
str(bank_data)
# 41,188 x 21 
# 10 numeric variables
# 10 character (categorical) variables 
# 1 integer (response variable)

glimpse(bank_data)
# unknown pulling through rather than NA
table(bank_data$y)
head(bank_data)

# Understanding Each Variable --------------------
names(bank_data)
# y (int) - response variable, subscribed or did not subscribe.
# contact (cat) - how respondent contacted
# campaign (num) - number of contacts made during campaign
# pdays (num) - days since last contact in previous campaign
# previous (num) -  number of contacts made before campaign
# poutcome (cat) - outcome of previous campaign
# age (num) - age of respondent
# job (cat) - type of occupation
# marital (cat)  - marital status
# education (cat) - education level
# housing (cat) - housing loan?
# loan (cat) - personal loan?
# default (cat) - has credit in default?
# month (cat) - month of last contact
# day_of_week (cat) - last contact day of week
# emp.var.rate (num) - employment variation rate, quarterly indicator
# cons.price.inx (num) - consumer price index, monthly indicator
# cons.conf.ind (num) - consumer confidence index, monthly indicator
# euribor3m (num) - euribor 3 month rate, daily indicator
# nr.employed (num) - number of employees, quarterly indicator
# duration (num) - last contact duration, excluded from predictors


# Missing Data Analysis ------------------------------

## Note: left this in for learning but not going to be used in remaining data prep

# previously identified that values come through as "unknown"
sapply(bank_data, function(x) sum(x== "unknown"))
# unknown data in variables, job (330), marital (80), education (1731), default (8597), housing (990), and loan (990).
# swapping "unknown" to NA for ease of code/analysis
bank_data_na <- bank_data %>%
  mutate(across(
    where(is.character),
    ~ na_if(.x, "unknown")
  ))

colSums(is.na(bank_data_na))

# Visualising missingness
gg_miss_var(bank_data_na, show_pct = TRUE) +
  labs(title = "Missing Values by Variable", 
       x = "Variables",
       y = "Proportion of Missing Values")
# default variable has the highest proportion of missing values (approx 21%)

aggr(bank_data_na, numbers = TRUE, prop = FALSE, sortVar = TRUE)
# left plot shows the amount of missing values for each variable
# right plot shows how often combinations of missing variables occur

vis_miss(bank_data_na)
# potential pattern of missingness across housing and loan - MAR or MNAR
gg_miss_case(bank_data_na)
miss_case_summary(bank_data_na)

# overall occurrence for missing data is low (1.8%) and there are only 2 variables where missingness is above 5% (education and default)
# joint missingness between housing and loan

# we should not use listwise deletion as the high number of missingness in "default" will cause a 5th of the data to be deleted


# Variable Analysis -------------------

## y -----------------------------
bank_data_proc = bank_data %>%
  mutate(subscribed = if_else(y =="yes", 1, 0))

## Contact ----------------------
bank_data %>%
  count(contact, y) %>%
  group_by(contact) %>%
  mutate(prop = n/sum(n))

ggplot(bank_data, aes(contact, fill = y)) +
  geom_bar(position = "fill") +
  coord_flip()
#Variable is significant. There is a higher percentage of subscribers out of those contacted
#by cellular vs those contacted by telephone
# Create two columns for contact where 1 = cellular and 0 = telephone
bank_data_proc = bank_data_proc %>%
  mutate(
  cellular_contact = if_else(contact == "cellular", 1, 0))

## Campaign ---------------------
bank_data %>% 
  ggplot() +
  aes(x = campaign) +
  geom_bar() +
  facet_grid(y ~ .,
             scales = "free_y") +
  scale_x_continuous(breaks = seq(0, 50, 5))

#Calling more than 10 times in a single campaign is excess and so these observations
#will be considered outliers

bank_data_proc = bank_data_proc %>%
  filter(campaign <=10)
bank_data_proc %>% 
  ggplot() +
  aes(x = campaign) +
  geom_bar() +
  facet_grid(y ~ .,
             scales = "free_y") +
  scale_x_continuous(breaks = seq(0, 10, 1))

bank_data_proc %>%
count(campaign, y) %>%
  group_by(campaign) %>%
  mutate(prop = n/sum(n))

skewness(bank_data_proc$campaign)
#High skew even after removing outliers so will perform a log transform
bank_data_proc = bank_data_proc %>%
  mutate(campaign_log = log(campaign))

#shows a decrease in subscriptions as number of calls increases


## Pdays ----------------------
table(bank_data_proc$pdays)

bank_data_proc %>% 
  filter(pdays !=999) %>% 
  ggplot(bank_data, mapping = aes(x = y, y = pdays)) +
  geom_boxplot()
# some significance the two response outcomes
# making this into a dummy variable for contacted vs not
bank_data_proc = bank_data_proc %>% 
  mutate(previously_contacted = if_else(pdays == 999, "0", "1")) %>% 
  select(-pdays)

ggplot(bank_data_proc, aes(pdays_dummy, fill = y)) +
  geom_bar(position = "fill") +
  coord_flip()
# can see a clear pattern of subscription of those who were contacted in a previous campaign


## Previous ----------------------------
# No point making this into a dummy variable as it will provide the same information as pdays
ggplot(bank_data_proc, aes(previous, fill = y)) +
  geom_bar(position = "fill")
# Leaving it as is for now but could bin it into 3 categories in the future
#bank_data = bank_data %>% 
#mutate(previous = if_else(previous >=  2, "2+", if_else(previous == 1, "1", "0")))
#may still be highly correlated with pdays
#removing for now as only interested in if they were previously ocntacted or not
bank_data_proc = bank_data_proc %>%
  select(-previous)

## Poutcome ----------------------------
ggplot(bank_data_proc, aes(poutcome, fill = y)) +
  geom_bar(position = "fill") +
  coord_flip()
#shows that there is a higher chance of subscription if the individual has subscribed in the past

## Age ---------------------------------
summary(bank_data_proc$age)
# other analysis transformed this data into categorical variable
#could be considered going forward
bank_data_proc %>% 
  ggplot() +
  aes(x = age) +
  geom_bar()
skewness(bank_data_proc$age)
#no need for transformation
## Job ---------------------------------
table(bank_data_proc$job)
bank_data_proc = bank_data_proc %>% 
  filter(job != "unknown")

## Marital -----------------------------
table(bank_data_proc$marital)
bank_data_proc = bank_data_proc %>% 
  filter(marital != "unknown")

## Education ---------------------------
#Not enough illiterate observations to make assumptions from, should be removed
bank_data_proc = bank_data_proc %>% 
  filter(education != "illiterate")

#Rather than removing all unknown observations, recoding these observations to university degree.
#These both have similar proportions of yes/no subscriptions
bank_data_proc = bank_data_proc %>% 
  mutate(education = recode(education, "unknown" = "university.degree"))

ggplot(bank_data_proc, aes(education, fill = y)) +
  geom_bar(position = "fill") +
  coord_flip()

## Housing -----------------------------
bank_data_proc %>%
  count(housing, y) %>%
  group_by(housing) %>%
  mutate(prop = n/sum(n))
#similar proportions across all categories
#test to see if significant against response
chisq.test(bank_data_proc$housing, bank_data_proc$y)
#bank_data_proc = bank_data_proc %>% 
  #select(-housing)

## Loan --------------------------------
bank_data_proc %>%
  count(loan, y) %>%
  group_by(loan) %>%
  mutate(prop = n/sum(n))
#similar proportions across all categories
#test to see if significant against response
chisq.test(bank_data_proc$loan, bank_data_proc$y)
#bank_data_proc = bank_data_proc %>% 
  #select(-loan)
bank_data_proc = bank_data_proc %>% 
  filter(loan != "unknown")

## Default -----------------------------
#20% of observations are unknown, removing this from the dataset
bank_data_proc = bank_data_proc %>% 
  select(-default)

## Month -------------------------------
bank_data_proc %>% 
  ggplot() +
  aes(x = month, y = ..count../nrow(bank_data), fill = y) +
  geom_bar() +
  ylab("relative frequency")

## Day_of_week -------------------------
bank_data_proc %>%
  count(day_of_week, y) %>%
  group_by(day_of_week) %>%
  mutate(prop = n/sum(n))

## Duration ----------------------------
#Removing as highly correlated with response variable
bank_data_proc = bank_data_proc %>% 
  select(-duration)

# Correlation Analysis ----------------

numeric_df <- bank_data_proc %>%
  select(where(is.numeric))

cor_matrix <- cor(numeric_df)

corrplot(
  cor_matrix,
  method = "number",
  type = "upper"
)

#highly correlated pairs:
#emp.var.rate and euribor3m
#emp.var.rate and nr.employed
#euribor3m and nr.employed

# euribor3m
ggplot(bank_data_proc, aes(euribor3m)) +
  geom_histogram(bins = 30)
ggplot(bank_data_proc, aes(x= y,y = euribor3m)) +
  geom_boxplot()
table(bank_data_proc$euribor3m)
skewness(bank_data_proc$euribor3m)

#emp.var.rate
ggplot(bank_data_proc, aes(emp.var.rate)) +
  geom_histogram(bins = 30)
ggplot(bank_data_proc, aes(x=y,y = emp.var.rate)) +
  geom_boxplot()
table(bank_data_proc$emp.var.rate)
skewness(bank_data_proc$emp.var.rate)

# nr.employed
ggplot(bank_data_proc, aes(nr.employed)) +
  geom_histogram(bins = 30)
ggplot(bank_data_proc, aes(x=y, y = nr.employed)) +
  geom_boxplot()
table(bank_data_proc$nr.employed)
skewness(bank_data_proc$nr.employed)

#emp.var.rate and nr.employed are similar variables
#nr.employed boxplot implies the nr.employed is more meaningful
#remove emp.var.rate 
bank_data_proc = bank_data_proc %>% 
  select(-emp.var.rate)

numeric_df <- bank_data_proc %>%
  select(where(is.numeric))

cor_matrix <- cor(numeric_df)

corrplot(
  cor_matrix,
  method = "number",
  type = "upper"
)

skewness(bank_data_proc$cons.conf.idx)
skewness(bank_data_proc$cons.price.idx)


# At the end of analysis we have transformed pdays into a dummy variable
# filtered unknowns out of job and marital variables
# filtered out illiterate observations from education and mutated unknowns to university level
# removed default, emp.var.rate, and duration variables