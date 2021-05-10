# atx traffic grabber

library(tidyverse)
library(tidycensus)
library(RSocrata)
library(lubridate)
library(sf)
library(tmap)

setwd("~/skool/spatial/atx/")

options(tigris_use_cache = TRUE)

# pull traffic data -------------------------------------------------------

# data source: https://data.austintexas.gov/

# specify date range
years_ago <- today() - years(2)

# execute API query
crash_url <- glue::glue("https://data.austintexas.gov/resource/dx9v-zd7x.json?$where=published_date > '{years_ago}'")

crash_raw <- as_tibble(read.socrata(crash_url))

# save crash data locally
write_rds(crash_raw, "data/crash_raw.rds")

# load shape file
atx_boundary <- st_read("data/BOUNDARIES_jurisdictions/geo_export_2c504b0f-ef27-4b85-b14a-ef7e457dface.shp")

# compile census commute data ---------------------------------------------

# data source: https://api.census.gov/data/2019/acs/acs5/profile/variables.html

acs_tables <- read_csv("data/acs_tables/acs_vars.csv")

# collect all estimate variables names for commute data
commute <- acs_tables %>% 
  filter(str_detect(Label, "COMMUTING") & str_detect(Label, "Estimate")) %>% 
  select(-c(Concept, Required, Limit, Group, X9, `Predicate Type`, Attributes)) %>% 
  mutate(Label = str_replace(Label, "!!COMMUTING TO WORK!!Workers 16 years and over", " "),
         Label = str_replace(Label, "!!", " "))

commute_vars <- list(commute$Name)

commute_by_tract <- get_acs(
  geography = "tract",
  state = "Texas",
  county = "Travis",
  survey = "acs5",
  year = 2019,
  output = "wide",
  variables = commute_vars[[1]]) # commute variables

# clean census data
commute_estimates <- commute_by_tract %>% 
  
  # remove GEOID and margin of error columns
  select(-c(GEOID, ends_with("M"))) %>% 
  
  # clean up columns and values
  rename("tract" = NAME,
         "total_commuters" = DP03_0018E,
         "drove_alone" = DP03_0019E,
         "carpooled" = DP03_0020E,
         "transit" = DP03_0021E,
         "walked" = DP03_0022E,
         "other_means" = DP03_0023E,
         "work_from_home" = DP03_0024E,
         "av_commute_time(minutes)" = DP03_0025E) %>% 
  mutate(tract = str_extract(tract, "[0-9\\.]+"))

# compute rates
commute_rates <- commute_estimates %>% 
  transmute(tract = tract,
            `av_commute_time(minutes)` = `av_commute_time(minutes)`,
            da_rate = drove_alone/total_commuters,
            cp_rate = carpooled/total_commuters,
            transit_rate = transit/total_commuters,
            walked_rate = walked/total_commuters,
            other_rate = other_means/total_commuters,
            wfh_rate = work_from_home/total_commuters)


# collect census median rent and home value data -----------------------------------------------------

rent_by_tract <- get_acs(
  geography = "tract",
  state = "Texas",
  county = "Travis",
  survey = "acs5",
  year = 2019,
  output = "wide",
  variables = "DP04_0134E")

med_rent_estimates <- rent_by_tract %>%
  
  # remove GEOID and margin of error columns
  select(NAME, DP04_0134E) %>% 
  
  # clean up columns and values
  rename("tract" = NAME,
         "med_rent" = DP04_0134E) %>% 
  mutate(tract = str_extract(tract, "[0-9\\.]+"))

# median home value, this is a table and not a variable. so can't combine with others
homeval_by_tract <- get_acs(
  geography = "tract",
  state = "Texas",
  county = "Travis",
  survey = "acs5",
  year = 2019,
  output = "wide",
  variables = "DP04_0089E")

med_homeval_estimates <- homeval_by_tract %>%
  
  # remove GEOID and margin of error columns
  select(NAME, DP04_0089E) %>% 
  
  # clean up columns and values
  rename("tract" = NAME,
         "med_homeval" = DP04_0089E) %>% 
  mutate(tract = str_extract(tract, "[0-9\\.]+"))

