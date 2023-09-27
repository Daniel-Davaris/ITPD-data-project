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


recreg <- read.csv("wholeRECdatabase_20230816_no_dups_withSTCs_Zone3.csv", stringsAsFactors = FALSE)
head(recreg)


### Quick Check quantity nationally installed in month ###
recreg_check <- recreg[recreg$Fuel_Source_Display_Name %in% "S.G.U. - solar (deemed)" & recreg$year %in% 2023,]
recreg_check$week <- week(recreg_check$date)

# some simple summaries
(aggregate(x=recreg_check$system_size_kW, by=list(month=recreg_check$month, year=recreg_check$year, type=recreg_check$Fuel_Source_Display_Name), FUN=sum, na.rm=T))
(aggregate(x=recreg_check$num_recs, by=list(month=recreg_check$month, year=recreg_check$year, type=recreg_check$Fuel_Source_Display_Name), FUN=sum, na.rm=T))
(aggregate(x=recreg_check$num_recs, by=list(week=recreg_check$week, year=recreg_check$year, type=recreg_check$Fuel_Source_Display_Name), FUN=sum, na.rm=T))

FYTD_whole <- recreg_check[(recreg_check$month %in% c(7,8,9,10,11,12) & recreg_check$year %in% 2022) |
                      (recreg_check$month %in% c(1,2,3,4,5,6) & recreg_check$year %in% 2023),]
sum(FYTD_whole$system_size_kW)
### END Quick Check quantity nationally installed in month ###



########## DATA MANIPULATION FOR ACTEWAGL REPORT #################
my.month <- 9
my.year <- 2019
if(my.month < 10){my.month.c <- paste0("0", my.month)} else {my.month.c <- my.month}
my.period <- paste0(my.year, my.month.c)

my.seq <- c(7,8,9,10,11,12,1,2,3,4,5,6)
fy.seq <- my.seq[seq(from=1, to=which(my.seq == my.month), by=1)]
fy.years <- my.year
if(my.month < 7){fy.years <- c(my.year, my.year-1)}


####################### ACT ONLY #######################################

act.solar <- recreg[recreg$Fuel_Source_Display_Name %in% "S.G.U. - solar (deemed)" & recreg$State %in% "ACT" & 
                     !recreg$Status.1 %in% "Invalid due to audit",]
count(act.solar, c('Status.1'))
head(act.solar)

# Total installed this month
act.solar.backup <- act.solar
act.total.installs <- data.frame(Total_installs = nrow(act.solar.backup[act.solar.backup$year %in% my.year & act.solar.backup$month %in% my.month,]), 
                                 Installed_capacit = sum(act.solar.backup$system_size_kW[act.solar.backup$year %in% my.year & act.solar.backup$month %in% my.month]))

# remove those greater than 15kW as client only interested in large
act.solar <- act.solar[act.solar$system_size_kW < 15,]

# For graph 1 part A
library(dplyr)
act.monthly.installs <- act.solar %>% count(year, month)
# (act.monthly.installs <- count(act.solar, c('year','month')))
colnames(act.monthly.installs) <- c("Year", "Month", "Installs")
act.monthly.installs <- act.monthly.installs %>% 
  filter(!is.na(Year))

################################# Last 12 months only#####################
# Convert my.year and my.month into a Date object for the first day of the month
end_date <- as.Date(paste0(my.year, "-", my.month, "-01"))

# Calculate the starting date for the 13-month window by subtracting 12 months from end_date 
start_date <- seq.Date(from = end_date, by = "-1 months", length.out = 13)[13]

# Filter rows of act.monthly.installs to keep only the last 13 months of data
act.monthly.installs2 <- act.monthly.installs[act.monthly.installs$Year * 100 + act.monthly.installs$Month >= as.numeric(format(start_date, "%Y%m")) &
                                      act.monthly.installs$Year * 100 + act.monthly.installs$Month <= as.numeric(format(end_date, "%Y%m")), ]
colnames(act.monthly.installs2) <- c("Year", "Month", "Total")

# General interest in ACT
act.monthly.system_size <- aggregate(x=act.solar$system_size_kW, by=list(month=act.solar$month,year=act.solar$year), FUN=sum, na.rm=T)
colnames(act.monthly.system_size) <- c("Month", "Year", "Installed_kW")
## erroneous due to phantom RECS before Jan 2013
(act_monthly.total <- merge(act.monthly.installs, act.monthly.system_size))
act_monthly.total$average_kW <- act_monthly.total$Installed_kW / act_monthly.total$Installs
act_monthly.total <- act_monthly.total[order(act_monthly.total$Year, act_monthly.total$Month),]
# write.csv(act_monthly.total, "act2023.market.csv", row.names=F)

################################# ACT INSTALLS ONLY #######################
act_actew <- act.solar[(act.solar$Created_By %in% "ICON RETAIL INVESTMENTS LIMITED AND AGL ACT RETAIL INVESTMENTS PTY LTD" |
                          act.solar$Created_By %in% "ACTEW RETAIL LTD and AGL ACT RETAIL INVESTMENTS PTY LTD"),]
act_actew[act_actew$year %in% my.year & act_actew$month %in% my.month,]

act_actew.monthly <- aggregate(x=act_actew$system_size_kW, by=list(month=act_actew$month,year=act_actew$year), FUN=sum, na.rm=T)

## create row with NA values for months with no creation of reccs
# Create the full sequence of month/year combinations
full_sequence <- expand.grid(
  month = 1:12,
  year = min(act_actew.monthly$year):my.year
)
# Filter up to my.month and my.year
full_sequence <- full_sequence %>%
  filter(full_sequence$year < my.year | (full_sequence$year == my.year & full_sequence$month <= my.month))

# Left join with your original data to get the missing rows
act_actew.monthly <- full_sequence %>%
  left_join(act_actew.monthly, by = c("month", "year"))


################################# GRAPH 1 PART B ###########################
## create row with NA values for months with no creation of reccs
(act_actew.monthly.count <- act_actew %>% count(year, month))

# Left join with your original data to get the missing rows
act_actew.monthly.count <- full_sequence %>%
  left_join(act_actew.monthly.count, by = c("month", "year"))

# Filter rows of act_actew.monthly.count to keep only the last 13 months of data
act_actew.monthly.count2 <- act_actew.monthly.count[act_actew.monthly.count$year * 100 + act_actew.monthly.count$month >= as.numeric(format(start_date, "%Y%m")) &
                                                      act_actew.monthly.count$year * 100 + act_actew.monthly.count$month <= as.numeric(format(end_date, "%Y%m")), ]
colnames(act_actew.monthly.count2) <- c("Month", "Year", "ActewAGL")


################################# GRAPH 1 ##################################
(act_actew.monthly.total <- merge(act.monthly.installs2, act_actew.monthly.count2))
act_actew.monthly.total$Other <- act_actew.monthly.total$Total - act_actew.monthly.total$ActewAGL
act_actew.monthly.total <- act_actew.monthly.total[order(act_actew.monthly.total$Year, act_actew.monthly.total$Month),]
act_actew.monthly.total$Month <- month.abb[act_actew.monthly.total$Month]
act_actew.monthly.total <- act_actew.monthly.total[,c(1,3,2,4,5)]
# tail(act.monthly.installs)

act2015 <- act.solar[act.solar$year %in% my.year,]
act2015.market <- count(act2015, c('Created_By'))
act2015.status <- count(act2015, c('Status.1'))

# ACT WHOLE FINALCIAL YEAR
if(my.month < 7) {ACTFYTD_whole <- act.solar.backup[(act.solar.backup$month %in% my.seq[my.seq >= 7] & act.solar.backup$year %in% (my.year -1 )) |
                                                      (act.solar.backup$month %in% my.seq[my.seq < 7] & act.solar.backup$year %in% my.year),] } else {
                                                        ACTFYTD_whole <- act.solar.backup[(act.solar.backup$month %in% my.seq[my.seq >= 7] & act.solar.backup$year %in% my.year),]
                                                      }
sum(ACTFYTD_whole$system_size_kW)

# ACT Only
if(my.month < 7) {ACTFYTD <- act.solar[(act.solar$month %in% my.seq[my.seq >= 7] & act.solar$year %in% (my.year - 1)) |
                                         (act.solar$month %in% my.seq[my.seq < 7] & act.solar$year %in% my.year),]} else {
                                           ACTFYTD <- act.solar[(act.solar$month %in% my.seq[my.seq >= 7] & act.solar$year %in% my.year),]
                                         }
ACTFYTD.kW <- aggregate(x=ACTFYTD$system_size_kW, by=list(Created_By=ACTFYTD$Created_By), FUN=sum, na.rm=T)


#################### TABLE 2 #############################
ACTFYTD.installs <- ACTFYTD %>% count(Created_By)
(ACTFYTD.total <- merge(ACTFYTD.kW, ACTFYTD.installs))
ACTFYTD.total <- ACTFYTD.total[order(ACTFYTD.total$n,decreasing = T),]
ACTFYTD.total$Rank <- seq(1:nrow(ACTFYTD.total))
table2 <- rbind(ACTFYTD.total[1:10,], data.frame(Created_By="Other", x=sum(ACTFYTD.total$x[11:nrow(ACTFYTD.total)]), 
                                                 n=sum(ACTFYTD.total$n[11:nrow(ACTFYTD.total)]),
                                                 Rank=""))
table2 <- rbind(table2, data.frame(Created_By="Total", x=sum(ACTFYTD.total$x), n=sum(ACTFYTD.total$n), Rank=""))
table2$share <- table2$n / sum(ACTFYTD.total$n)
table2 <- table2[,c(4,1,2,3,5)]
names(table2) <- c("Rank", "Certificates Created By", "kW Installed", "Quantity", "Market Share")
(table2)

###### ACT MONTHLY
head(act.solar)
ACTJan2016 <- act.solar[act.solar$month %in% my.month & act.solar$year %in% my.year,]

## systems by size
ACTJan2016 <-  transform(ACTJan2016, group=cut(system_size_kW, 
                                               breaks=c(0,2,3,4,5,6,7,8,9,10,15),
                                               labels=c("0-2kW", "2-3kW", "3-4kW", "4-5kW", "5-6kW", "6-7kW", "7-8kW", "8-9kW", "9-10kW", "10kW+")))

######################### GRAPH 2 #############################
graph2 <- ACTJan2016 %>% count(group)
colnames(graph2) <- c("PV System", "Quantity")


sum(ACTJan2016$system_size_kW)
nrow(ACTJan2016)
sum(ACTJan2016$system_size_kW) / nrow(ACTJan2016)

# ACTJan2016.market <- count(ACTJan2016, c('Created_By'))
ACTJan2016.market <- ACTJan2016 %>% count(Created_By)
ACTJan2016.market2 <- aggregate(x=ACTJan2016$system_size_kW, by=list(Created_By=ACTJan2016$Created_By), FUN=sum, na.rm=T)

##################### TABLE 1 ############################
(ACTJan2016.market.total <- merge(ACTJan2016.market2, ACTJan2016.market))
ACTJan2016.market.total <- ACTJan2016.market.total[order(ACTJan2016.market.total$n,decreasing = T),]
row.names(ACTJan2016.market.total) <- NULL
ACTJan2016.market.total$Rank <- seq(1:nrow(ACTJan2016.market.total))
table1 <- rbind(ACTJan2016.market.total[1:10,], data.frame(Created_By="Other", x=sum(ACTJan2016.market.total$x[11:nrow(ACTJan2016.market.total)]), 
                                                           n=sum(ACTJan2016.market.total$freq[11:nrow(ACTJan2016.market.total)]),
                                                           Rank=""))
table1 <- rbind(table1, data.frame(Created_By="Total", x=sum(ACTJan2016.market.total$x), n=sum(ACTJan2016.market.total$freq), Rank=""))
table1$share <- table1$n / sum(ACTJan2016.market.total$n)
table1 <- table1[,c(4,1,2,3,5)]

names(table1) <- c("Rank", "Certificates Created By", "kW Installed", "Quantity", "Market Share")
(table1)


######################### MARET SHARE ######################
write.table(table1, paste0(my.period, " ActewAGL marketshare data.csv"), col.names=TRUE, row.names=FALSE, sep=",")
write.table(table2, paste0(my.period, " ActewAGL marketshare data.csv"), col.names=FALSE, row.names=FALSE, sep=",", append=TRUE)
write.table(act.total.installs, paste0(my.period, " ActewAGL marketshare data.csv"), col.names=FALSE, row.names=FALSE, sep=",", append=TRUE)

######################### TOTAL INSTALLS ######################
write.table(act_actew.monthly.total, paste0(my.period, " ActewAGL Total Installs data.csv"), col.names=TRUE, row.names=FALSE, sep=",")
write.table(graph2, paste0(my.period, " ActewAGL Total Installs data.csv"), col.names=FALSE, row.names=FALSE, sep=",", append=TRUE)
