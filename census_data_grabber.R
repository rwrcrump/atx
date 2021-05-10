# census tables and variables

library(tidyverse)
library(tidycensus)

setwd("~/skool/spatial/atx/")

# full variable list. dont forget to load API key
acs5_vars_2019 <- load_variables(2019, "acs5")

write_csv(acs5_vars_2019, "acs5_vars_2019.csv")

# tables copied from https://api.census.gov/data/2019/acs/acs5/profile/variables.html
acs_tables <- read_csv("data/acs_tables&variables/acs_vars.csv")

# collect all estimate variables names for commute data
commute <- acs_tables %>% 
  filter(str_detect(Label, "COMMUTING") & str_detect(Label, "Estimate")) %>% 
  select(-c(Concept, Required, Limit, Group, X9, `Predicate Type`, Attributes)) %>% 
  mutate(Label = str_replace(Label, "!!COMMUTING TO WORK!!Workers 16 years and over", " "),
         Label = str_replace(Label, "!!", " "))

var_list <- list(commute$Name)

commute_estimates <- get_acs(
  geometry = TRUE,
  geography = "tract",
  state = "Texas",
  county = "Travis",
  survey = "acs5",
  year = 2019,
  output = "wide",
  variables = var_list[[1]]) # commute variables



