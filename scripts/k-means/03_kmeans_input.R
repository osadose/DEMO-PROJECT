# Setting up input data for k-means clustering ---------------

cluster_input <- bank_behaviour %>%
  select(
    index,
    subscription_propensity,
    previously_contacted,
    poutcome,
    campaign_log,
    cellular_contact
  )

# One hot encoding --------------

# Identify all character/factor columns except y
categorical_vars <- bank_data_proc %>%
  select(poutcome) %>%
  names()

# Encode
cluster_input <- dummy_cols(
  cluster_input,
  select_columns = categorical_vars,
  remove_selected_columns = TRUE
)

str(cluster_input)
cluster_input$previously_contacted <- as.numeric(cluster_input$previously_contacted)

# Scale check
round(
  colMeans(cluster_input),
  5
)

round(
  apply(cluster_input, 2, sd),
  5
)
