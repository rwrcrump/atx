library(tidyverse)
library(RSocrata)
library(lubridate)
library(sf)
library(tmap)

setwd("~/skool/spatial/atx/")

# pull traffic data -------------------------------------------------------

# data source: https://data.austintexas.gov/

# specify date range
years_ago <- today() - years(2)

# execute API query
crash_url <- glue::glue("https://data.austintexas.gov/resource/dx9v-zd7x.json?$where=published_date > '{years_ago}'")

crash_raw <- as_tibble(read.socrata(crash_url))

crash_raw <- na.omit(crash_raw)

crash_shp <- st_as_sf(crash_raw, coords = c("longitude", "latitude"))

coa_tracts <- st_read("data/generated_shp_files/coa_tracts/coa_tracts.shp")

crash_shp <- st_set_crs(crash_shp, st_crs(coa_tracts))

coa_traffic_data <- st_join(coa_tracts, crash_shp)

# save crash data locally
st_write(crash_raw, "data/generated_shp_files/coa_crashes(points)/")
