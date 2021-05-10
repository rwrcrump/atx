library(tidyverse)
library(RSocrata)
library(sf)
library(tmap)

setwd("~/skool/spatial/atx/")

#data source: https://data.austintexas.gov/

atx_boundary <- st_read("data/BOUNDARIES_jurisdictions/geo_export_2c504b0f-ef27-4b85-b14a-ef7e457dface.shp")

coa_limits <- atx_boundary %>% 
  filter(jurisdicti == "AUSTIN FULL PURPOSE")

tm_shape(coa) +
  tm_fill() +
  tm_borders() 

MSA_tracts <- st_read("data/Boundaries_ Austin MSA Census Tracts 2010/geo_export_60234b6b-2112-47a8-bd4c-586066ef4ac7.shp")

MSA_tracts <- MSA_tracts %>% 
  select(tractce10, geometry)

tm_shape(MSA_tracts) +
  tm_fill() +
  tm_borders()

intersects <- st_intersects(MSA_tracts, coa_limits)

coa_tracts <- filter(coa_tracts, lengths(intersects) > 0)

test <- st_union(coa_tracts)

tm_shape(test) +
  tm_fill() +
  tm_borders()


