library("skimr")
library("tidyverse")
library("here")
library("lubridate")
library("tibble")
library("zoo")
library("xts")


preprocessing <- function(
  dataset_path,
  dataset_export_path,
  dataset_skip = 20,
  
) {
  # Load dataset
  my_data <- readr::read_csv(dataset_path, skip = 20)
  
  
  # Mark out-range values to "NA"
  exclude_cols <- c("YEAR", "DOY")
  my_data[, !colnames(my_data) %in% exclude_cols] <- 
    lapply(my_data[, !colnames(my_data) %in% exclude_cols], 
           function(col) { col[col == -999] <- NA; col })

  
  # Make sure that T2M_MIN <= T2M <= T2M_MAX
  my_data %>% filter(!(T2M >= T2M_MIN & T2M <= T2M_MAX)) %>% {
    if (nrow( . > 0))
      print("Something is wrong.")
    return(FALSE)
  }
  
  
  # Remove NA values
  find_na_rows <- apply(is.na(my_data[, !names(my_data) %in% exclude_cols]), 1, all)
  idx_of_na_rows <- which(find_na_rows)
  my_data <- my_data
  
  
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
    # Ensure input is in Date format
    d <- as.Date(date)
    # Calculate Julian Day Number (Microsoft Standard offset)
    jd <- as.numeric(d) + 2440588
    # Kuwaiti Algorithm parameters for lunar cycle synchronization
    l <- jd - 1948440 + 10632
    n <- floor((l - 1) / 10631)
    l <- l - 10631 * n + 354
    # Determine Islamic Year and Month through cyclical iteration
    j <- (floor((10985 - l) / 5316)) * (floor((50 * l) / 17719)) + 
      (floor(l / 5670)) * (floor((43 * l) / 15238))
    l <- l - (floor((30 - j) / 20)) * (floor((17719 * j) / 50)) - 
      (floor(j / 25)) * (floor((15238 * j) / 43)) + 29
    # Calculate Hijri Month (9 corresponds to Ramadan)
    m <- floor((24 * l) / 709) 
    # Calculate Hijri Year
    y <- n * 30 + j - 30       
    # Return TRUE if the month is Ramadan (9)
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
  my_data <- readr::write_csv(my_data, dataset_export_path)
  
  return(TRUE)
}