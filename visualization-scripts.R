library("tidyverse")
library("lubridate")
library("broom")
library("trend")
library("Kendall")


chart_long_temperature_overview <- function(
    dataset, result_export_path, city_name
) {
  dataset %>% 
    ggplot() +
    geom_line(aes(x = full_date, y = temp_air_mean_c), 
              linewidth = 0.2, color = "grey60") +
    geom_smooth(aes(x = full_date, y = temp_air_mean_c),
                method = "loess",
                span = 0.4,
                se = FALSE,
                color = "red", 
                linewidth = 1.1) +
    scale_x_date(
      date_breaks = "1 year", 
      date_labels = "%Y",
      expand = c(0.01, 0.01)
    ) +
    labs(title = paste0("Mean Daily Temperature – ", city_name, " (2013–2025)"),
         x = "Year", y = "Temperature (C°)") +
    theme_minimal()
  ggsave(paste0(result_export_path, "long-term temperature overview (2013–2025).png"))
}


chart_yearly_with_ramadan <- function(
    dataset,
    result_export_complete_path,
    selected_year,
    y_column,
    y_label,
    chart_title
) {
  dataset %>% filter(year == selected_year) %>% ggplot() +
    geom_line(mapping = aes(x = full_date, y = .data[[y_column]])) +
    geom_line(data = . %>% filter(is_ramadan == TRUE), mapping = aes(x = full_date, y = .data[[y_column]]), color = "red") +
    geom_smooth(aes(x = full_date, y = .data[[y_column]]),
                method = "loess",
                span = 0.4,
                se = FALSE,
                color = "gray50", 
                linewidth = 1.1) +
    scale_x_date(
      date_breaks = "1 month",
      date_labels = "%b",
      expand = c(0.01, 0.01)
    ) +
    labs(title = chart_title,
         subtitle = "Red segment = Ramadan period", x = "Month", y = y_label)
  ggsave(result_export_complete_path)
}


chart_recent_temperatures_comparation <- function(
    dataset, result_export_path, city_name
) {
  my_colors <- c(
    "2021" = "#1f77b4",
    "2022" = "#ff7f0e",
    "2023" = "#2ca02c",
    "2024" = "#d62728",
    "2025" = "#9467bd"
  )
  
  start_year <- 2021
  end_year   <- 2025
  
  p <- ggplot() +
    
    lapply(start_year:end_year, function(yr) {
      geom_smooth(
        data = filter(dataset, year == yr),
        aes(x    = day_of_year,
            y    = temp_air_mean_c,
            color = factor(yr, levels = start_year:end_year)),
        method   = "loess",
        span     = 0.4,
        se       = FALSE,
        linewidth = 0.6,
        show.legend = TRUE
      )
    }) +
    
    scale_color_manual(
      values = my_colors,
      name   = "Year",
      labels = as.character(start_year:end_year)
    ) +
    
    scale_x_continuous(
      breaks = seq(0, 366, by = 30),
      limits = c(1, 366),
      expand = expansion(mult = c(0.01, 0.01))
    ) +
    
    labs(
      title    = paste0("Loess Smoothed Daily Mean Temperature of ", city_name, " (", start_year, "–", end_year, ")"),
      x        = "Day of Year",
      y        = "Temperature (C°)",
      color    = "Year"
    ) +
    
    theme_minimal(base_size = 13) +
    theme(
      legend.position       = c(0.98, 0.98),
      legend.justification  = c("right", "top"),
      legend.background     = element_rect(fill = "white", color = "gray80", linewidth = 0.4),
      legend.title          = element_text(face = "bold"),
      legend.text           = element_text(size = 9),
      panel.grid.minor.x    = element_blank(),
      plot.title.position   = "plot"
    )
  ggsave(paste0(result_export_path, "yearly temperature with Ramadan highlight (", selected_year, ").png"))
}


chart_comparing_ramadan_to_previous_years <- function(
    dataset, 
    result_export_path, 
    city_name,
    start_date,
    end_date,
    top_padding
) {
  for (ith_year in end_date:(start_date + 1)) {
    ramadan_data <- dataset %>% 
      filter(year == ith_year & is_ramadan == TRUE) %>% 
      select(day_of_year, full_date, rolling_avg_30)
    
    last_day_index <- which.max(ramadan_data$day_of_year)
    last_day_doy <- ramadan_data$day_of_year[last_day_index]
    last_day_date <- ramadan_data$full_date[last_day_index]
    ramadan_temperature <- ramadan_data$rolling_avg_30[last_day_index]
    
    data <- dataset %>% 
      filter(day_of_year == last_day_doy & year >= start_date & year <= ith_year) %>% 
      select(day_of_year, full_date, year, rolling_avg_30)
    
    the_plot <- data %>% 
      ggplot() +
      geom_point(aes(x = full_date, y = rolling_avg_30), color = "blue") +
      labs(title = paste0("30-day Rolling Avg on Last Day of Ramadan ", ith_year, " vs Past Years"),
           subtitle = paste0("Comparing end-of-Ramadan temperature of ", city_name, " in ", ith_year, " to same date in previous years"), x = "Year", y = "30-day Rolling Avgerage Temperature (C°)",) +
      annotate("text", x = last_day_date, y = ramadan_temperature, 
               label = "x", color = "red") +
      scale_x_date(date_breaks = "12 month", date_labels = "%Y") +
      scale_y_continuous(breaks = seq(-40, 40, 5)) +
      geom_hline(yintercept = mean(data$rolling_avg_30), linetype = "dashed", color = "darkgreen", linewidth = 1) +
      annotate("text", x = mean(data$full_date), y = mean(data$rolling_avg_30) + top_padding,
               label = paste0("Historical Mean = ", round(mean(data$rolling_avg_30), 2)), color = "darkgreen") +
      theme(plot.margin = margin(20, 20, 20, 20))
    
    # Add value labels for each point
    for (idx in 1:nrow(data)) {
      the_plot <- the_plot + 
        annotate("text", x = data[[idx, "full_date"]], 
                 y = data[[idx, "rolling_avg_30"]] + top_padding,
                 label = round(data[[idx, "rolling_avg_30"]], 2), angle = 0)
    }
    
    ggsave(paste0(result_export_path, "30-day Rolling Avg on Last Day of Ramadan ", ith_year, " vs Past Years.png"))
  }
}


table_statistical_trend_summary <- function(
    data, result_export_path, city_name
) {
  analyze_trend <- function(df_month) {
    
    # Early exit if too few years → regression not meaningful
    if (nrow(df_month) < 3) {
      return(tibble(
        month = unique(df_month$month),
        note  = "Fewer than 3 years of data"
      ))
    }
    
    # Linear model: temperature ~ year
    model <- lm(mean_heat_index ~ year, data = df_month)
    
    slope     <- coef(model)[2]
    p_value   <- glance(model)$p.value
    r_squared <- glance(model)$r.squared
    years     <- max(df_month$year) - min(df_month$year) + 1
    total_change <- slope * (years - 1)
    
    # Non-parametric trend test
    mk_test <- MannKendall(df_month$mean_heat_index)
    
    # Decide trend category using both parametric (lm) and non-parametric (MK) results
    trend_type <- case_when(
      p_value > 0.05 & mk_test$sl > 0.05   ~ "No significant trend",
      slope > 0   & mk_test$sl <= 0.05     ~ "Significant increasing trend",
      slope < 0   & mk_test$sl <= 0.05     ~ "Significant decreasing trend",
      TRUE                                 ~ "Weak or oscillating trend"
    )
    
    # Return summary row
    tibble(
      month          = unique(df_month$month),
      slope_per_year = round(slope, 4),
      total_change   = round(total_change, 2),
      lm_p           = round(p_value, 4),
      mk_p           = round(mk_test$sl, 4),
      mk_tau         = round(mk_test$tau, 3),
      trend          = trend_type
    )
  }
  
  trend_summary <- data %>%
    group_by(month) %>%
    group_split() %>%
    map_dfr(analyze_trend) %>%
    arrange(month)
  
  readr::write_csv(trend_summary, paste0(result_export_path, city_name, '_statistical trend summary per month.csv'))
}


chart_monthly_mean_heat_index_trend <- function(
    dataset, 
    result_export_path, 
    city_name
) {
  data <- tibble()
  all_years <- levels(as.factor(dataset$year))
  
  for (month in 1:12) {
    temp_data <- tibble()
    for (year in all_years) {
      start_date <- ymd(paste0(year, "-", month, "-", "01"))
      end_date <- ceiling_date(start_date, "month") - days(1)
      
      period <- dataset %>% filter(full_date >= start_date & full_date <= end_date)
      
      mean_temperature <- mean(period$temp_air_mean_c, na.rm = TRUE) 
      mean_heat_index <- mean(period$HI_standard, na.rm = TRUE)
      
      temp_data <- rbind(temp_data, tibble(year=year(start_date), month=month(start_date), mean_temperature=mean_temperature, mean_heat_index=mean_heat_index))
    }
    
    the_plot = temp_data %>% ggplot() +
      geom_line(aes(x = year, y = mean_heat_index), color = "grey70", linewidth = 0.6) +
      geom_smooth(
        aes(x = year, y = mean_heat_index),
        method = "lm",
        se = FALSE, 
        color = "red", linewidth = 1.3, linetype = "solid"
      ) +
      geom_point(aes(x = year, y = mean_heat_index), color = "darkblue", size = 2.2) +
      labs(x = "Year", y = "Mean Heat Index (C°)", 
           title = paste0("Mean Heat Index Trend of ", city_name, " in ", month.name[month]),
           subtitle = paste0(month.name[month], " from ", min(all_years), " to ", max(all_years))) +
      scale_x_continuous(
        breaks = seq(min(temp_data$year), max(temp_data$year), by = 1),
        labels = function(x) floor(x)
      ) +
      geom_text(
        aes(
          x = year,
          y = mean_heat_index,
          label = sprintf("%.2f", mean_heat_index),
          color = mean_heat_index > mean(mean_heat_index, na.rm = TRUE)
        ),
        vjust = -0.6,
        size = 3.5
      ) +
      scale_color_manual(values = c("blue", "red"), guide = "none")
    ggsave(paste0(result_export_path, "monthly mean Heat Index trends across years - ", month.name[month],".png"))
    data <- rbind(data, temp_data)
  }
  readr::write_csv(data, paste0(result_export_path, city_name, '_monthly mean Heat Index trends across years.csv'))

  # Statistical trend summary per month
  table_statistical_trend_summary(data, result_export_path, city_name)
}


chart_extreme_temperature_by_month <- function(
    dataset, 
    result_export_path, 
    city_name,
    start_year,
    end_year
) {
  extreme_temperature_days <- dataset %>% 
    filter(is_extreme_hot == TRUE | is_extreme_cold == TRUE)
  
  result_wide <- extreme_temperature_days %>%
    mutate(
      month_name = month(full_date, label = TRUE, abbr = FALSE)
    ) %>%
    group_by(month_name) %>%
    summarise(
      very_hot  = sum(is_extreme_hot,  na.rm = TRUE),
      very_cold = sum(is_extreme_cold, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      month_name = factor(month_name, levels = month.name)
    )
  
  result_long <- result_wide %>%
    pivot_longer(
      cols = c(very_hot, very_cold),
      names_to = "temperature_type",
      values_to = "count"
    )
  
  ggplot(result_long, aes(x = month_name, y = count, fill = temperature_type)) +
    
    geom_col(position = position_dodge(width = 0.35), width = 0.35) +
    
    geom_text(
      aes(
        label = count,
        y = count
      ),
      position = position_dodge(width = 0.70),
      vjust = -0.4,
      size = 3.4,
      fontface = "bold",
      color = "black"
    ) +
    
    scale_fill_manual(
      values = c("very_hot"   = "#d73027", 
                 "very_cold" = "#4575b4"),
      labels = c("very_hot"   = "Very Hot", 
                 "very_cold" = "Very Cold")
    ) +
    
    scale_x_discrete(name = "Month") +
    
    labs(
      y = "Number of Days",
      title = paste0("Number of Extreme Hot and Cold Days by Month in ", city_name),
      subtitle = paste0("Only days with extreme temperatures (from ", start_year, " to ", end_year, ")"),
      fill = NULL
    ) +
    
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  ggsave(paste0(result_export_path, "extreme temperature days by month (hot vs cold).png"))
}


table_ramadan_extreme_days <- function(
    dataset, result_export_path, city_name
) {
  extreme_temperature_ramadan_days <- dataset %>%
    filter(is_ramadan == TRUE & (is_extreme_hot == TRUE | is_extreme_cold == TRUE))
  
  ramadan_days_total <- dataset %>% filter(is_ramadan == TRUE)
  
  ramadan_extreme_ratio <- nrow(extreme_temperature_ramadan_days) / nrow(ramadan_days_total)
  
  percentage <- round(ramadan_extreme_ratio * 100, 1)
  
  result <- data.frame("percentage" = c(percentage), "city" = c(city_name))
  
  readr::write_csv(result, paste0(result_export_path, city_name, '_calculate percentage of extreme days during Ramadan (full period).csv'))
}


chart_year_by_year_comparison <- function(
    dataset, result_export_path, city_name
) {
  yearly_summary <- dataset %>%
    mutate(year = year(full_date)) %>%
    group_by(year) %>%
    summarise(
      total_extreme = sum(is_extreme_hot | is_extreme_cold, na.rm = TRUE),
      ramadan_extreme = sum((is_extreme_hot | is_extreme_cold) & is_ramadan, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    pivot_longer(cols = c(total_extreme, ramadan_extreme),
                 names_to = "type",
                 values_to = "count")
  
  ggplot(yearly_summary, aes(x = as.factor(year), y = count, fill = type)) +
    geom_col(position = position_dodge(width = 0.35), width = 0.35) +
    geom_text(
      aes(
        label = count,
        y = count
      ),
      position = position_dodge(width = 0.70),
      vjust = -0.4,
      size = 3.4,
      fontface = "bold",
      color = "black"
    ) +
    scale_fill_manual(
      values = c("total_extreme"   = "#999999", 
                 "ramadan_extreme" = "#d73027"),
      labels = c("total_extreme"   = "Full Year", 
                 "ramadan_extreme" = "Ramadan")
    ) +
    labs(
      x = "Year",
      y = "Number of Extreme Temperature Days",
      title = paste0("Extreme Temperature Days in Ramadan vs. Full Year in ", city_name),
      fill = NULL
    ) +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  ggsave(paste0(result_export_path, "year-by-year comparison - Extreme days in Ramadan vs. full year.png"))
}


visualizations <- function(
  dataset_file_path,
  result_export_path,
  city_name
) {
  # Read dataset
  my_data <- readr::read_csv(dataset_file_path)
  
  # Long-term temperature overview (2013–2025)
  chart_long_temperature_overview(
    dataset = my_data,
    result_export_path = result_export_path,
    city_name = city_name
    )
  
  
  # Yearly temperature with Ramadan highlight (selected year)
  chart_yearly_with_ramadan(
    dataset = my_data,
    result_export_complete_path = paste0(result_export_path, "yearly temperature (", selected_year, ").png"),
    selected_year = 2024,
    y_column = "temp_air_mean_c",
    y_label = "Temperature (C°)",
    chart_title = paste0("Daily Mean Temperature – ", city_name, ", ", selected_year)
    )
  
  
  # Same style comparison for humidity
  chart_yearly_with_ramadan(
    dataset = my_data,
    result_export_complete_path = paste0(result_export_path, "Yearly humidity (", selected_year, ").png"),
    selected_year = 2024,
    y_column = "humidity_relative_percent",
    y_label = "Humidity",
    chart_title = paste0("Relative Humidity – ", city_name, ", ", selected_year)
  )
  
  
  # For wind speed
  chart_yearly_with_ramadan(
    dataset = my_data,
    result_export_complete_path = paste0(result_export_path, "Wind Speed (", selected_year, ").png"),
    selected_year = 2024,
    y_column = "wind_speed_ms",
    y_label = "Wind Speed(m/s)",
    chart_title = paste0("Wind Speed – ", city_name, ", ", selected_year)
  )
  
  
  # For dew point
  chart_yearly_with_ramadan(
    dataset = my_data,
    result_export_complete_path = paste0(result_export_path, "Dew Point Temperature (", selected_year, ").png"),
    selected_year = 2024,
    y_column = "temp_dewpoint_c",
    y_label = "Dew Point Temperature",
    chart_title = paste0("Dew Point Temperature – ", city_name, ", ", selected_year)
  )
  
  
  # For daily temperature range
  chart_yearly_with_ramadan(
    dataset = my_data,
    result_export_complete_path = paste0(result_export_path, "Diurnal Temperature Variation (", selected_year, ").png"),
    selected_year = 2024,
    y_column = "temp_range",
    y_label = "Diurnal Temperature Variation",
    chart_title = paste0("Diurnal Temperature Variation – ", city_name, ", ", selected_year)
  )
  
  
  # For vapor pressure deficit
  chart_yearly_with_ramadan(
    dataset = my_data,
    result_export_complete_path = paste0(result_export_path, "Vapor Pressure Deficit (", selected_year, ").png"),
    selected_year = 2024,
    y_column = "vpd_kpa",
    y_label = "Vapor Pressure Deficit",
    chart_title = paste0("Vapor Pressure Deficit – ", city_name, ", ", selected_year)
  )
  
  
  # For heat index standard
  chart_yearly_with_ramadan(
    dataset = my_data,
    result_export_complete_path = paste0(result_export_path, "Heat Index Standard (", selected_year, ").png"),
    selected_year = 2024,
    y_column = "HI_standard",
    y_label = "Heat Index (Standard)",
    chart_title = paste0("Heat Index (Standard) – ", city_name, ", ", selected_year)
  )
  
  
  # For thermal discomfort delta
  chart_yearly_with_ramadan(
    dataset = my_data,
    result_export_complete_path = paste0(result_export_path, "Thermal Discomfort Delta (", selected_year, ").png"),
    selected_year = 2024,
    y_column = "heat_index_rel_temp",
    y_label = "Thermal Discomfort Delta",
    chart_title = paste0("Thermal Discomfort Delta – ", city_name, ", ", selected_year)
  )
    
  
  # For 30-day rolling average
  chart_yearly_with_ramadan(
    dataset = my_data,
    result_export_complete_path = paste0(result_export_path, "30-day rolling average (", selected_year, ").png"),
    selected_year = 2024,
    y_column = "rolling_avg_30",
    y_label = "30-day rolling average",
    chart_title = paste0("30-day rolling average – ", city_name, ", ", selected_year)
  )
  
  
  # For 7-day rolling average
  chart_yearly_with_ramadan(
    dataset = my_data,
    result_export_complete_path = paste0(result_export_path, "7-day rolling average (", selected_year, ").png"),
    selected_year = 2024,
    y_column = "rolling_avg_7",
    y_label = "7-day rolling average",
    chart_title = paste0("7-day rolling average – ", city_name, ", ", selected_year)
  )
  
  
  # Recent temperatures from 2021-2025
  chart_recent_temperatures_comparation(
    dataset = my_data, 
    result_export_path = result_export_path, 
    city_name = city_name
  )
  
  
  # Comparing end-of-Ramadan rolling average to previous years
  chart_comparing_ramadan_to_previous_years(
    dataset = my_data, 
    result_export_path = result_export_path, 
    city_name = city_name,
    start_date = 2013,
    end_date = 2025,
    top_padding = 0.2
  )
  
  
  # Monthly mean Heat Index trends across years
  chart_monthly_mean_heat_index_trend(
    dataset = my_data, 
    result_export_path = result_export_path, 
    city_name = city_name
  )
  
  
  # Extreme temperature days by month (hot vs cold)
  chart_extreme_temperature_by_month(
    dataset = my_data, 
    result_export_path = result_export_path, 
    city_name = city_name,
    start_year = 2013,
    end_year = 2025
  )
  
  
  # Calculate percentage of extreme days during Ramadan (full period)
  table_ramadan_extreme_days(
    dataset = my_data, 
    result_export_path = result_export_path, 
    city_name = city_name
  )
  
  
  # Year-by-year comparison: Extreme days in Ramadan vs. full year
  chart_year_by_year_comparison(
    dataset = my_data, 
    result_export_path = result_export_path, 
    city_name = city_name
  )
}



# list of datasets
datasets_list <- c(
  "birjand_clean_dataset.csv",
  "singapore_clean_dataset.csv",
  "mexico-city_clean_dataset.csv",
  "rio-de-janeiro_clean_dataset.csv",
  "riyadh_clean_dataset.csv",
  "dubai_clean_dataset.csv",
  "bandar-abbas_clean_dataset.csv",
  "cairo_clean_dataset.csv",
  "isfahan_clean_dataset.csv",
  "adelaide_clean_dataset.csv",
  "rasht_clean_dataset.csv",
  "tabriz_clean_dataset.csv",
  "nevada_clean_dataset.csv",
  "ankara_clean_dataset.csv",
  "barcelona_clean_dataset.csv",
  "london_clean_dataset.csv",
  "moscow_clean_dataset.csv",
  "oslo_clean_dataset.csv",
  "svalbard_clean_dataset.csv"
)

work_directory <- "D:\\climetr\\climetr_analysis\\"

fs::dir_create(paste0(work_directory, 'result'))

for (dataset_path in datasets_list) {
  print(paste0(work_directory, 'datasets\\', dataset_path))
  city_name <- tolower(str_split(dataset_path, "_")[[1]][1])
  path <- paste0(work_directory, 'result\\', city_name)
  
  # make a folder with name of city
  fs::dir_create(path)
  
  visualizations(
    dataset_file_path = paste0(work_directory, 'datasets\\', dataset_path),
    result_export_path = paste0(path, "\\"),
    city_name = city_name
  )
}


