# atx traffic analysis

rm(list = ls())

library(tidyverse)
library(tidycensus)
library(RSocrata)
library(lubridate)
library(sf)
library(tmap)

setwd("~/skool/spatial/atx/")

options(tigris_use_cache = TRUE)

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
  geometry = TRUE,
  geography = "tract",
  state = "Texas",
  county = "Travis",
  survey = "acs5",
  year = 2019,
  output = "wide",
  variables = commute_vars[[1]])

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
         "av_commute_time(minutes)" = DP03_0025E)

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

# spatial boundaries -----------------------------------------------------

#data source: https://data.austintexas.gov/

atx_boundary <- st_read("data/BOUNDARIES_jurisdictions/geo_export_2c504b0f-ef27-4b85-b14a-ef7e457dface.shp")

coa_limits <- atx_boundary %>% 
  filter(jurisdicti == "AUSTIN FULL PURPOSE")

# conform CRS to city boundary
commute_rates <- st_transform(commute_rates, st_crs(coa_limits))

# array of logical values, limiting county to city 
intersects <- st_intersects(commute_rates, coa_limits)

coa_tracts <- filter(commute_rates, lengths(intersects) > 0)

# not sure why some tracts are missing data
tm_shape(coa_tracts) +
  tm_fill("da_rate") +
  tm_borders()

# create single polygon shape from tract borders
coa_tract_boundary <- st_union(coa_tracts)

tm_shape(coa_tract_boundary) +
  tm_fill() +
  tm_borders()

# pull traffic data -------------------------------------------------------

# data source: https://data.austintexas.gov/

# specify date range
years_ago <- today() - years(2)

# execute API query
crash_url <- glue::glue("https://data.austintexas.gov/resource/dx9v-zd7x.json?$where=published_date > '{years_ago}'")

crash_raw <- as_tibble(read.socrata(crash_url))

crash_drop_na <- na.omit(crash_raw)

crash_shp <- st_as_sf(crash_drop_na, coords = c("longitude", "latitude"))

# conform CRS
crash_shp <- st_set_crs(crash_shp, st_crs(coa_tracts))

tm_shape(coa_tracts) +
    tm_fill() +
    tm_borders() +
  tm_shape(crash_shp) +
  tm_dots()
  
# save data locally -------------------------------------------------------

write_rds(crash_raw, "data/crash_raw.rds")

st_write(crash_shp, "data/generated_shp_files/coa_crashes(points)/crash_shp.shp")

st_write(coa_tracts, "data/generated_shp_files/coa_tracts/coa_tracts.shp")

st_write(coa_tract_boundary, "data/generated_shp_files/coa_tract_boundary/coa_tract_boundary.shp")

