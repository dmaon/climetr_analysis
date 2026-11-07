library("skimr")
library("tidyverse")
library("here")
library("lubridate")
library("tibble")
library("zoo")
library("xts")

preprocessing <- function(
  dataset_file_path,
  dataset_export_file_path,
  dataset_skip = 20
) {
  # Load dataset
  my_data <- readr::read_csv(dataset_file_path, skip = 20)

  
  # Mark out-range values to "NA"
  exclude_cols <- c("YEAR", "DOY")
  my_data[, !colnames(my_data) %in% exclude_cols] <- 
    lapply(my_data[, !colnames(my_data) %in% exclude_cols], 
           function(col) { col[col == -999] <- NA; col })

  
  # Make sure that T2M_MIN <= T2M <= T2M_MAX
  rows <- my_data %>% filter(!(T2M >= T2M_MIN & T2M <= T2M_MAX))
    if (nrow(rows) > 0) {
      print("Something is wrong.")
    return(FALSE)
  }
  
  
  # Remove NA values
  find_na_rows <- apply(is.na(my_data[, !names(my_data) %in% exclude_cols]), 1, all)
  idx_of_na_rows <- which(find_na_rows)
  my_data <- my_data[-idx_of_na_rows, ]
  
  
  # Rename columns names
  my_data <- my_data %>% 
    rename(
      year = YEAR,
      day_of_year              = DOY,
      temp_air_mean_c          = T2M,
      temp_air_max_c           = T2M_MAX,
      temp_air_min_c           = T2M_MIN,
      humidity_relative_percent = RH2M,
      wind_speed_ms            = WS2M,
      wind_direction_deg       = WD2M,
      precip_total_mm          = PRECTOTCORR,
      pressure_surface_kpa     = PS,
      radiation_solar_mj_m2_day = ALLSKY_SFC_SW_DWN,
      temp_dewpoint_c          = T2MDEW,
      temp_wetbulb_c           = T2MWET,
      humidity_specific_gpkg   = QV2M
    )

  
  # Add date column
  my_data <- my_data %>% mutate(full_date = as.Date(day_of_year - 1, origin = paste0(year, "-01-01")))
  my_data <- my_data %>% mutate(month_number = month(full_date))

  
  # Add temperature range
  my_data <- my_data %>% mutate(temp_range = temp_air_max_c - temp_air_min_c)

  
  # Add VPD
  es <- function(T) 0.6108 * exp(17.27 * T / (T + 237.3))
  my_data <- my_data %>% mutate(vpd_kpa = es(temp_air_mean_c) - es(temp_dewpoint_c))

  
  # Add heat index
  compute_heat_index_noaa <- function(temp_c, rh) {
    # 1. Handle invalid humidity values (outside 0-100 range) by converting to NA
    rh[rh < 0 | rh > 100] <- NA_real_
    # 2. Convert air temperature from Celsius to Fahrenheit
    temp_f <- 1.8 * temp_c + 32.0
    # 3. Calculate the "Simple Formula" for the Heat Index
    hi_simple <- 0.5 * (temp_f + 61.0 + (temp_f - 68.0) * 1.2 + rh * 0.094)
    # Initialize the final HI vector with the simple formula results (as per NOAA logic)
    hi_final_f <- hi_simple
    # 4. Handle very low temperatures (below 40°F / 4.44°C)
    # According to NOAA/NWS, the Heat Index is equal to the air temperature in these cases
    low_temp_idx <- which(temp_f <= 40.0)
    if (length(low_temp_idx) > 0) {
      hi_final_f[low_temp_idx] <- temp_f[low_temp_idx]
    }
    # 5. Calculate the average of hi_simple and temp_f to determine the threshold for regression
    hi_avg <- (hi_simple + temp_f) / 2
    # Identify records that require the complex Rothfusz Regression (HI >= 80°F)
    use_roth <- !is.na(hi_avg) & (hi_avg >= 80.0) & (temp_f > 40.0)
    idx <- which(use_roth)
    if (length(idx) > 0) {
      Tf <- temp_f[idx]
      Rh <- rh[idx]
      # Primary Rothfusz Regression Equation
      hi_roth <- -42.379 + 
        2.04901523 * Tf + 
        10.14333127 * Rh - 
        0.22475541 * Tf * Rh - 
        0.00683783 * Tf^2 - 
        0.05481717 * Rh^2 + 
        0.00122874 * Tf^2 * Rh + 
        0.00085282 * Tf * Rh^2 - 
        0.00000199 * Tf^2 * Rh^2
      # Low Relative Humidity Adjustment (Low RH Adjustment)
      low_cond <- (Rh < 13) & (Tf >= 80 & Tf <= 112)
      if (any(low_cond)) {
        adj_low <- ((13 - Rh[low_cond]) / 4) * sqrt(pmax(0, (17 - abs(Tf[low_cond] - 95)) / 17))
        hi_roth[low_cond] <- hi_roth[low_cond] - adj_low
      }
      # High Relative Humidity Adjustment (High RH Adjustment)
      high_cond <- (Rh > 85) & (Tf >= 80 & Tf <= 87)
      if (any(high_cond)) {
        adj_high <- ((Rh[high_cond] - 85) / 10) * ((87 - Tf[high_cond]) / 5)
        hi_roth[high_cond] <- hi_roth[high_cond] + adj_high
      }
      # Replace simple values with the more precise regression results where applicable
      hi_final_f[idx] <- hi_roth
    }
    # Final unit conversion back to Celsius for output
    hi_final_c <- (hi_final_f - 32) * (5/9)
    return(hi_final_c)
  }
  my_data <- my_data %>%
    mutate(
      HI_standard = compute_heat_index_noaa(temp_air_mean_c, humidity_relative_percent),
      HI_filtered = ifelse(temp_air_mean_c >= 27 & humidity_relative_percent >= 40, HI_standard, NA)
    )
  
  
  # Add thermal discomfort delta
  my_data <- my_data %>%
    mutate(heat_index_rel_temp = HI_standard - temp_air_mean_c)
  
  
  # Add is_ramadan column by Kuwaiti algorithm
  is_ramadan_kuwaiti <- function(date) {
    d <- as.Date(date)
    
    jd <- as.numeric(d) + 2440588   # days since 1970 + offset
    
    epoch <- 1948084
    z <- jd - epoch
    cyc <- floor(z / 10631)
    z <- z - 10631 * cyc
    
    j <- floor((z - 0.133333) / (10631 / 30))   # shift ≈ 8.01/60
    iy <- 30 * cyc + j
    z <- z - floor(j * (10631 / 30) + 0.133333)
    
    im <- floor((z + 28.5001) / 29.5)
    if (im == 13) im <- 12
    
    m <- im 
    y <- iy + 1 
    
    return(m == 9)
  }
  my_data <- my_data %>%
    mutate(is_ramadan = sapply(full_date, is_ramadan_kuwaiti))
  
  
  # Add rolling statistics
  my_data <- my_data %>%
    mutate(
      rolling_avg_7 = rollmean(temp_air_mean_c, k = 7,  align = "right", fill = NA),
      rolling_avg_30 = rollmean(temp_air_mean_c, k = 30, align = "right", fill = NA),
      rolling_sd_7 = rollapply(temp_air_mean_c, width = 7, FUN = sd, align = "right", fill = NA),
      rolling_sd_30 = rollapply(temp_air_mean_c, width = 30, FUN = sd, align = "right", fill = NA),
      temp_anomaly = temp_air_mean_c - rolling_avg_30,
      is_extreme_hot = temp_air_mean_c > (rolling_avg_30 + 2 * rolling_sd_30),
      is_extreme_cold = temp_air_mean_c < (rolling_avg_30 - 2 * rolling_sd_30)
    )
  
  
  # Add daily_anomaly
  climatology <- my_data %>%
    group_by(day_of_year) %>%
    summarise(
      mean_temp_doy = mean(temp_air_mean_c, na.rm = TRUE),
      mean_hi_doy   = mean(heat_index_rel_temp, na.rm = TRUE),
      .groups = "drop"
    )
  
  my_data <- my_data %>%
    left_join(climatology, by = c("day_of_year")) %>%
    mutate(
      temp_anomaly = temp_air_mean_c - mean_temp_doy,
      hi_anomaly   = heat_index_rel_temp - mean_hi_doy
    )

  
  # Save dataset 
  my_data <- readr::write_csv(my_data, dataset_export_file_path)
  
  return(TRUE)
}



# list of datasets
datasets_list <- c(
  "POWER_Point_Daily_20130101_20251123_032d86N_059d22E_LST_Birjand.csv",
  "POWER_Point_Daily_20130101_20251125_001d35N_103d82E_LST_Singapore.csv",
  "POWER_Point_Daily_20130101_20251125_019d43N_099d13W_LST_Mexico-city.csv",
  "POWER_Point_Daily_20130101_20251125_022d91S_043d17W_LST_Rio-de-janeiro.csv",
  "POWER_Point_Daily_20130101_20251125_024d71N_046d68E_LST_Riyadh.csv",
  "POWER_Point_Daily_20130101_20251125_025d27N_055d30E_LST_Dubai.csv",
  "POWER_Point_Daily_20130101_20251125_027d19N_056d27E_LST_Bandar-abbas.csv",
  "POWER_Point_Daily_20130101_20251125_030d04N_031d23E_LST_Cairo.csv",
  "POWER_Point_Daily_20130101_20251125_032d65N_051d68E_LST_Isfahan.csv",
  "POWER_Point_Daily_20130101_20251125_034d93S_138d60E_LST_Adelaide.csv",
  "POWER_Point_Daily_20130101_20251125_037d28N_049d58E_LST_Rasht.csv",
  "POWER_Point_Daily_20130101_20251125_038d08N_046d29E_LST_Tabriz.csv",
  "POWER_Point_Daily_20130101_20251125_039d53N_0119d81W_LST_Nevada.csv",
  "POWER_Point_Daily_20130101_20251125_039d93N_032d85E_LST_Ankara.csv",
  "POWER_Point_Daily_20130101_20251125_041d39N_002d17E_LST_Barcelona.csv",
  "POWER_Point_Daily_20130101_20251125_051d51N_000d13W_LST_London.csv",
  "POWER_Point_Daily_20130101_20251125_055d76N_037d62E_LST_Moscow.csv",
  "POWER_Point_Daily_20130101_20251125_059d91N_010d75E_LST_Oslo.csv",
  "POWER_Point_Daily_20130101_20251125_078d22N_015d65E_LST_Svalbard.csv"
)




work_directory <- "D:\\climetr\\climetr_analysis\\"
path <- paste0(work_directory, 'datasets')
fs::dir_create(path)

for (dataset_path in datasets_list) {
  file_name <- str_split(dataset_path, "_")[[1]][9]
  city_name <- tolower(substr(file_name, 0, nchar(file_name) - 4)) # for getting city name
  
  preprocessing(
    dataset_file_path = paste0(path, '\\', dataset_path),
    dataset_export_file_path = paste0(path, '\\', city_name, "_clean_dataset.csv"),
    dataset_skip = 20
  )
}
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
