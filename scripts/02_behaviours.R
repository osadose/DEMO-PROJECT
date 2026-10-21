# Script to create all the behaviours we want to segment on, based on user needs
# Model each behaviour, then cluster on these

#Dataframe with relevant variables for behaviour creation
bank_behaviour <- bank_data_proc %>%
  select(-y) %>%
  select(-campaign) %>%
  select(-contact)

# Subscription propensity

propensity_model <- glm(
  subscribed ~ age + 
    job +
    marital +
    education + 
    housing +
    loan +
    month +
    day_of_week + 
    poutcome + 
    cons.price.idx + 
    cons.conf.idx + 
    euribor3m + 
    nr.employed + 
    cellular_contact +
    campaign_log +
    previously_contacted,
  data = bank_behaviour,
  family = binomial()
)

summary(propensity_model)

bank_behaviour <- bank_behaviour %>%
  mutate(
    subscription_propensity = predict(
      propensity_model,
      newdata = bank_behaviour,
      type = "response"
    )
  )

# Prior engagement
# Will use the variables already in the table (poutcome, previously_contacted)

