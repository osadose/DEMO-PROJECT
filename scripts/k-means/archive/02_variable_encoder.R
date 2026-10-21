# The current dataset contains categorical data which cannot be used by the k-means algorithm
# ordinal encoding will be used to transform education from categorical to numerical
# one-hot encoding will be used for the remaining categorical variables

## Education --------------------
table(bank_data_proc$education)

education_levels <- c("basic.4y", "basic.6y", "basic.9y", "high.school", "professional.course", "university.degree")
bank_data_proc$education_encoded <- as.integer(factor(bank_data_proc$education, levels = education_levels, ordered = TRUE))
#check
table(bank_data_proc$education_encoded)
bank_data_proc = bank_data_proc %>% 
  select(-education)
rename(bank_data_proc, education = education_encoded)

## Remaining categorical variables -----------

# Identify all character/factor columns except y
categorical_vars <- bank_data_proc %>%
  select(where(~ is.character(.) | is.factor(.))) %>%
  select(-y) %>%
  names()

# One-hot encode
bank_data_proc <- dummy_cols(
  bank_data_proc,
  select_columns = categorical_vars,
  remove_selected_columns = TRUE
)

# Changing response to binary
bank_data_proc$y <- ifelse(bank_data_proc$y=="yes", 1, 0)
glimpse(bank_data_proc)
