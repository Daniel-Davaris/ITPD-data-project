library(data.table)
library(httr)
library(plyr)
require(XML)
require(RCurl)
library(stringr)
library(reshape2)
library(tidyr)
library(dplyr)
library(rlang)
library(magrittr)

# Cacluate PV systems size based on # of STCs, Postcode Zone and installation year
# Example usage:
# calculate_system_size(num_STCs = 100, zone = 1, installation_year = 2016)
calculate_system_size <- function(num_STCs, zone, installation_year) {
  # Postcode Zone Ratings
  zone_ratings <- c('1' = 1.622, '2' = 1.536, '3' = 1.382, '4' = 1.185)
  # Deeming period (years) by installation year
  deeming_years <- c(
    '2016' = 15, '2017' = 14, '2018' = 13, '2019' = 12,
    '2020' = 11, '2021' = 10, '2022' = 9, '2023' = 8,
    '2024' = 7, '2025' = 6, '2026' = 5, '2027' = 4,
    '2028' = 3, '2029' = 2, '2030' = 1
  )
  # Check if provided zone and year are valid
  if (!(as.character(zone) %in% names(zone_ratings))) {
    stop("Invalid zone provided.")
  }
  if (!(as.character(installation_year) %in% names(deeming_years))) {
    stop("Invalid installation year provided.")
  }
  # Calculate system size
  system_size <- round_any(num_STCs / zone_ratings[as.character(zone)] / deeming_years[as.character(installation_year)], .01)
  return(system_size)
}


setwd("C:/Users/mtalent/Desktop/")
recreg <- read.csv("wholeRECdatabase_20230816_no_dups.csv", stringsAsFactors = FALSE)

# Format Dates
recreg$date <- str_split_fixed(recreg$Creation_Date, "T", 2)[,1]
recreg$date <- as.POSIXlt(recreg$date, format="%Y-%m-%d", tz="Australia/Canberra")
recreg$month <- recreg$date$mon+1
recreg$year <- recreg$date$year+1900
recreg$date <- as.POSIXct(recreg$date) #so data.table works

# Calculate number of certificates
recreg$num_recs <- as.numeric(recreg$End_Serial) - as.numeric(recreg$Start_Serial) + 1

# Calculate system size  ##### ERROR TO BE FIX, ASSUMES ZONE 3 FOR ALL SITES #####
# Add system_size_kW column for rows with Fuel_Source_Type == 'SGU_SOLAR_DEEMED'
recreg$system_size_kW <- as.numeric(NA)  # initializing the new column with NAs

# Calculate system_size_kW for the filtered rows
# Warning takes a long time to compute to done as data.table
# Convert dataframe to data.table
setDT(recreg)

# Update system_size_kW for rows with Fuel_Source_Type == 'SGU_SOLAR_DEEMED'
recreg[Fuel_Source_Type == 'SGU_SOLAR_DEEMED', 
       system_size_kW := calculate_system_size(num_STCs = num_recs, 
                                               zone = 3, 
                                               installation_year = year)]


write.csv(recreg, "wholeRECdatabase_20230816_no_dups_withSTCs_Zone3.csv", row.names=F)

