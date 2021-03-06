# ---- libraries ----
library(dplyr)
library(glue)
library(lubridate)
library(purrr)
library(stringr)
library(tibble)

# ---- load-data ----
rpts <- c(
  "bro" = "acus74.kbro.psh.bro.txt",
  "crp" = "acus74.kcrp.psh.crp.txt",
  "ewx" = "acus74.kewx.psh.ewx.txt",
  "hgx" = "acus74.khgx.psh.hgx.txt",
  "lch" = "acus74.klch.psh.lch.txt",
  "lix" = "acus74.klix.psh.lix.txt"
)

# Read data
txt <- map(rpts, ~readLines(here::here(glue("./data/{.x}"))))

# ---- slp ----
# Section A. Lowest Sea Level Pressure
# Section B. Marine Obs
slp_raw <- c(map(txt, ~.[grep("^A\\.", .):grep("^C\\.", .)])) %>%
  flatten_chr()

# Get a count of all rows that begin with a latitude followed by longitude.
# This will tell me exactly how many records I have.
# * \\s between lat and lon may be one or multiple lengths.
slp_obs_ptn <- "^\\d\\d\\.\\d\\d\\s*-*\\d\\d\\d*\\.\\d\\d.+"
slp_n <- sum(str_count(slp_raw, slp_obs_ptn))

# Get indices of values for n
slp_obs_n <- str_which(slp_raw, slp_obs_ptn)
# The location for the obs will be the line immediatley preceeding it.
# Therefore, we can get the station data by calculating x - 1
slp_stations_n <- slp_obs_n - 1

# Load stations
# Here, I trim the strings then take the nchar of longest string, round to
# nearest ten and pad the string. I'll use this to help extract data.
slp_stations <-
  slp_raw[slp_stations_n] %>%
  str_trim() %>%
  str_pad(width = round(max(nchar(.)), digits = -1), side = "right") %>%
  # Replace first "-" with "\t" to help split ID and Station
  str_replace("\\s*-\\s*", "\t")

# Load observations and trim
slp_obs <- slp_raw[slp_obs_n]

# Combine stations and obs
slp <- str_c(slp_stations, slp_obs)

# Expected names of dataset
slp_df_names <- c(
  "txt", "ID", "Station", "Lat", "Lon", "Pres", "PresDTd",
  "PresDThm", "PresRmks", "WindDir", "Wind", "WindDTd",
  "WindDThm", "WindRmks", "GustDir", "Gust", "GustDTd",
  "GustDThm", "GustRmks"
)

# Begin extraction. Move to dataframe and rename variables.
slp_df <-
  str_match(
    slp,
    sprintf("^%s%s%s%s%s%s%s%s%s%s%s%s$",
            # ID-Station
            "(\\w+)\t*(?<=\t{0,1})(.+)(?=\\s+\\d{2}\\.\\d{2})",
            # Lat
            "\\s+(\\d{2}\\.\\d{2})",
            # Lon
            "\\s+-*(\\d{2,6}\\.\\d{2})",
            # Pres
            "\\s+(\\d{1,4}\\.\\d{1})*",
            # PresDTd, PresDThm
            "\\s+(\\w{1,3}|N)*/*(\\w{1,4})*",
            # PresRmks
            "\\s+(I)*",
            # WindDir, Wind
            "\\s+(\\w{3})/(\\d{3})",
            # Wind DTd, WindDThm
            "\\s+(\\d{2,3})*/*(\\d{3,4})*",
            # WindRmks
            "\\s+(I)*",
            # GustDir, Gust
            "\\s+(\\w{3})*/*(\\d{3})*",
            # GustDTd, GustDThm
            "\\s+(\\d{2,3})*/*(\\d{3,4})*",
            # GustRmks
            "\\s+(I)*"
    )
  ) %>%
  as_tibble(.name_repair = "minimal") %>%
  set_names(nm = slp_df_names) %>%
  arrange(ID) %>%
  select(-txt)

# Begin clean-up
# Trim all values
slp_df <- mutate_all(slp_df, .funs = str_trim)

# Clean up Pres variables
slp_df$Pres[slp_df$Pres %in% c("0", "0.0", "9999.0")] <- NA
slp_df$PresDTd[slp_df$PresDTd %in% c("N", "MM", "99", "206")] <- NA
slp_df$PresDThm[slp_df$PresDThm %in% c("A", "9999")] <- NA

# Clean up Wind variables
slp_df$WindDir[slp_df$WindDir %in% c("999", "MMM")] <- NA
slp_df$Wind[slp_df$Wind %in% c("999")] <- NA
slp_df$WindDTd[slp_df$WindDTd %in% c("000", "99")] <- NA
slp_df$WindDThm[slp_df$WindDThm %in% c("9999")] <- NA

# Clean up Gust variables
slp_df$GustDir[slp_df$GustDir %in% c("MMM", "999")] <- NA
slp_df$Gust[slp_df$Gust %in% c("999")] <- NA
slp_df$GustDTd[slp_df$GustDTd %in% c("99")] <- NA
slp_df$GustDThm[slp_df$GustDThm %in% c("000", "9999")] <- NA

# Convert numeric vars (with exception of date/time vars)
# For all positive Lon values, make negative
slp_df <- slp_df %>%
  mutate_at(.vars = vars(Lat:Pres, WindDir:Wind, GustDir:Gust),
            .funs = as.numeric) %>%
  mutate(Lon = if_else(Lon > 0, Lon * -1, Lon))

# Correct the Lon for KXPY. Google Maps puts Port Fourchon at
# 29.1055584,-90.2119496. Current values are 29.12, -903202.00.
# I'll modify -903202.00 to -90.32
slp_df$Lon[slp_df$ID == "KXPY" & slp_df$Lon == -903202.00] <- -90.32

# ID TXVC-4 has been inadvertently split because of the first hyphen (the ob
# is only an ID, no Station). Correct.
slp_df$ID[slp_df$ID == "TXVC" & slp_df$Station == "4"] <- "TXVC-4"
slp_df$Station[slp_df$ID == "TXVC-4"] <- NA

# Combine date variables for Pres, Wind, Gust to one POSIXct date variable
# Since all events of the storm occurred in August I can supply year, month.
# Some values will generate failure to parse due to being NA or other
# invalid date or time.
slp_df <-
  slp_df %>%
  mutate(
    PresDT = ymd_hm(sprintf("2017-08-%s %s", PresDTd, PresDThm)),
    WindDT = ymd_hm(sprintf("2017-08-%s %s", WindDTd, WindDThm)),
    GustDT = ymd_hm(sprintf("2017-08-%s %s", GustDTd, GustDThm))
  )

slp_df <- slp_df %>%
  select(ID:Pres, PresDT,PresRmks, Wind, WindDir, WindDT, WindRmks, Gust,
         GustDir, GustDT, GustRmks)

save(slp_df, file = here::here("./output/slp_df.rda"))

# ---- rain ----
# Section C. STORM TOTAL RAINFALL
rain_raw <- c(map(txt, ~.[grep("^C\\.", .):grep("^D\\.", .)]))  %>%
  flatten_chr()

rain_obs_ptn <- "^\\d\\d\\.\\d\\d\\s+-*\\d*\\d\\d\\.\\d\\d.*$"

rain_n <- sum(str_count(rain_raw, rain_obs_ptn))

rain_obs_n <- str_which(rain_raw, rain_obs_ptn)

rain_stations_n <- rain_obs_n - 1

rain_stations <- rain_raw[rain_stations_n] %>% str_trim()
max_n <- max(nchar(rain_stations))
rain_stations <- str_pad(rain_stations,
                         width = round(max_n, digits = -1),
                         side = "right")

rain_obs <- rain_raw[rain_obs_n]

rain <- str_c(rain_stations, rain_obs)

rain_df_names <- c(
  "txt", "Location", "County", "Station", "Rain", "RainRmks", "Lat", "Lon"
  )

rain_df <- str_match(rain,
                     pattern = sprintf("^%s%s\\s+%s\\s+%s\\s*%s\\s+%s\\s+%s$",
                                       "(.{29})",
                                       "(.{19})",
                                       "(.{0,12})",
                                       "(\\d{1,2}\\.\\d{2})",
                                       "(I)*",
                                       "(\\d{1,2}\\.\\d{2})",
                                       "-*(\\d{2,3}\\.\\d{2})")) %>%
  as_tibble(.name_repair = "minimal") %>%
  set_names(nm = rain_df_names) %>%
  mutate_at(.vars = c("Rain", "Lat", "Lon"), .funs = as.numeric) %>%
  mutate(Lon = if_else(Lon > 0, Lon * -1, Lon)) %>%
  select(-txt)

save(rain_df, file = here::here("./output/rain_df.rda"))

# ---- tors ----
# F. Tornadoes

# x = position data
# y = lat, lon row
# z = observation details
tor_raw <- c(map(txt, ~.[grep("^F\\.", .):grep("^G\\.", .)]))  %>%
  flatten_chr()

# This will cut out 4 tornado observations from KLIX.
tor_y_ptn <- "^\\d\\d\\.\\d\\d\\s+-*\\d*\\d\\d\\.\\d\\d.*$"

tor_n <- sum(str_count(tor_raw, tor_y_ptn))

tor_y_n <- str_which(tor_raw, tor_y_ptn)

tor_x_n <- tor_y_n - 1

tor_stations <- tor_raw[tor_x_n] %>% str_trim()
max_n <- max(nchar(tor_stations))
tor_stations <- str_pad(tor_stations,
                        width = round(max_n, digits = -1),
                        side = "right")

tor_obs <- tor_raw[tor_y_n]

# To extract details I identify all elements of tor_raw that contain only \\s
# as this tends to pre/proceed detail data of the observation. Once I know
# where the beginning delimiter is I then find the very next delimiter. With
# both of these values I'll map through tor_raw and subset the pieces.

# indices of tor_raw containing \\s elements
tor_z_n <- str_which(tor_raw, "^\\s*$")

# t is the indexes of tor_z_n which represent the first \\s after tor_obs
t <- match(c(tor_y_n + 1), tor_z_n)

# What indices of tor_z_n mark the beginning delimiter \\s
t_a <- tor_z_n[t]
# and the end delimiter
t_b <- tor_z_n[t + 1]

tor_details <- map2(t_a, t_b, ~tor_raw[.x:.y]) %>% flatten_chr()

# Now, at this point I want all the details on one line and to get rid of
# the extra stuff. So, basically, some more reorg and clean-up.
tor_details <- str_c(tor_details, collapse = "\n") %>%
  str_replace_all("\n\n+", "\t") %>%
  str_replace_all("\n", " ") %>%
  str_split("\t") %>%
  map(str_trim) %>%
  flatten_chr()

tor <- str_c(tor_stations, tor_obs)

tor_df_names <- c(
  "txt", "Location", "CountY", "Day", "Time", "Scale", "Lat", "Lon"
)

tor_df <- str_match(tor, sprintf("^%s%s%s\\s+%s\\s+%s\\s+%s$",
                                 "(.{29})",
                                 "(.{17})",
                                 "(\\d{2})/(\\d{4})",
                                 "(\\w{3})",
                                 "\\s+(\\d{2}\\.\\d{2})",
                                 "\\s+(-\\d{2}\\.\\d{2})$")) %>%
  as_tibble(.name_repair = "minimal") %>%
  set_names(nm = tor_df_names) %>%
  mutate(Date = ymd_hm(sprintf("2017-08-%s %s", Day, Time))) %>%
  mutate_at(.vars = c("Lat", "Lon"), .funs = as.numeric) %>%
  select(-txt) %>%
  {.}

# Now add in tor_details
tor_df$Details <- tor_details

save(tor_df, file = here::here("./output/tor_df.rda"))
