# chicago shapefile extracts

library(tidyverse)
library(RSocrata)
library(lubridate)
library(sf)
library(tmap)

setwd("~/skool/spatial/atx/")

atx_boundary <- st_read("data/BOUNDARIES_jurisdictions/geo_export_2c504b0f-ef27-4b85-b14a-ef7e457dface.shp")

