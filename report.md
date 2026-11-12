# Multi-City Climate Dynamics, Biometeorological Trends, and Thermal Conditions During Ramadan (2013–2025)

**Author:** Noor Ahmad (dima) Khosravi (@dmaon)  
**Series:** Multi-City Climate Analytics Research Monograph  
**Repository:** climetr_analysis (GitHub)  

---

## 1. Abstract

In this study, I examine the multi-decadal climatic dynamics, localized warming trends, and seasonal bioclimatic conditions across five climatically diverse urban centers in Iran—**Bandar Abbas, Birjand, Isfahan, Rasht, and Tabriz**—over a 13-year period (2013–2025). Using daily high-resolution meteorological data from the NASA Prediction of Worldwide Energy Resources (POWER) reanalysis project, I engineered bioclimatic metrics including the NOAA Rothfusz Heat Index, Vapor Pressure Deficit, and rolling window temperature anomalies. 

The investigation originated from an exploratory hypothesis: whether ambient meteorological conditions during the Islamic holy month of Ramadan differ from those during non-Ramadan periods in ways that may indicate more favorable thermal conditions. Because the Hijri lunar calendar shifts through the Gregorian year by approximately 10–11 days annually, Ramadan moved from July/August in 2013 to February/March in 2025. 

OLS regression and Mann–Kendall trend tests identified a statistically significant increasing **November Heat Index trend across all five cities**, with estimated slopes ranging from +0.268 to +0.355 °C/year. Over the 12 elapsed years between 2013 and 2025, these slopes correspond to fitted trend changes of approximately +3.22 to +4.26 °C. In contrast, summer warming trends remain geographically confined to the southern Persian Gulf coast (Bandar Abbas) and eastern arid plateau (Birjand). 

Finally, I provide a methodological critique of rolling-window anomaly detection, the boundary behavior of local polynomial regression (LOESS), and the biometeorological validity of using the Heat Index during sub-zero winter regimes.

---

## 2. Project Background and Research Motivation

### 2.1 Project Genesis and Analytical Evolution
The **CLIMETR** analytical project began as a practical programming and data analysis exercise while I was completing the Google Data Analytics Professional Certificate on Coursera. My initial inquiry addressed a cultural-meteorological hypothesis common in regional discussions:
> *"Are atmospheric conditions during the Holy Month of Ramadan inherently milder, cooler, or more thermally tolerable than during the rest of the year, or is perceived comfort purely a function of Gregorian seasonal progression?"*

To test this hypothesis empirically, I created an R pipeline to ingest satellite observations, derive human comfort indices, identify lunar dates programmatically, and quantify anomalies. As the analysis progressed, the scope broadened. Because the lunar Hijri calendar regresses through the solar seasons by roughly 11 days per year, any perceived "moderation" during a given multi-year window reflects astronomical calendar drift rather than an intrinsic localized atmospheric anomaly tied to Ramadan itself.

Consequently, I expanded the research architecture into a comparative multi-city climate analytics pipeline. I scaled the codebase to process 19 worldwide cities across diverse climate zones, ultimately producing comprehensive diagnostic reports for five Iranian cities that represent major Köppen climate classifications:
1. **Bandar Abbas:** Coastal Persian Gulf hot desert/semi-arid climate ($BWh/BSh$).
2. **Birjand:** Eastern Iranian continental arid to semi-arid plateau ($BWk/BSk$).
3. **Isfahan:** Central Iranian arid highland river basin ($BWk/BSk$).
4. **Rasht:** South Caspian coastal plain humid subtropical climate ($Cfa$).
5. **Tabriz:** Northwestern high-elevation intermontane cold semi-arid climate ($BSk$).
---

## 3. Research Objectives and Formal Questions

### 3.1 Original Documented Hypotheses
In the repository's core planning documentation (`research-questions.qmd` and `requirements.qmd`), I initially formulated four explicit research questions:

1. **Question 1 (End-of-Ramadan Climatological Deviation):**  
   $$\Delta T_{\text{end\_ramadan}} = \overline{T}_{30,\text{last\_day}} - \mu_{\text{historical}}(\text{DOY}_{\text{last\_day}})$$  
   *Does the 30-day backward-looking rolling average temperature on the final day of Ramadan in any given year exhibit a statistically meaningful deviation relative to the multi-year historical baseline observed on that exact calendar date (Day of Year)?*
2. **Question 2 (Comparative Urban Thermal Volatility):**  
   *Which urban centers experience the most severe diurnal and intra-seasonal thermal swings during Ramadan, and how do regional moisture regimes modulate physiological thermal stress across distinct climatic zones?*
3. **Question 3 (Seasonal Clustering of Extreme Events):**  
   *In which calendar months do statistically extreme hot and extreme cold days cluster, and how does the choice of baseline window influence this seasonal distribution?*
4. **Question 4 (Decadal Inter-Annual Dynamics):**  
   *How do monthly mean temperatures and perceived heat index values vary across different years, and do specific calendar months display secular warming or cooling trends over the 13-year observation window (2013–2025)?*

### 3.2 Evolution and Emergent Analytical Objectives in City Reports
As the analytical pipeline expanded from exploratory scripts (`visualization.Rmd`) into the five individual urban assessment reports (**Bandar Abbas, Birjand, Isfahan, Rasht, and Tabriz**), the scope deepened beyond the original cultural inquiry. Because the Islamic lunar calendar shifts by roughly 10 to 12 days annually relative to the Gregorian solar year, Ramadan traverses all four astronomical seasons over a ~33-year cycle. Consequently, perceived thermal comfort during Ramadan is primarily governed by solar seasonality rather than a unique local microclimatic moderation.

This realization prompted four additional analytical objectives that were integrated directly into the final city reports:
* **Identification of Asymmetric Decadal Warming:** Rather than assuming uniform year-round warming, the analysis was restructured to fit independent monthly Ordinary Least Squares (OLS) models and Mann–Kendall rank tests to determine whether warming is concentrated in specific transitional months (e.g., late autumn vs. mid-summer).
* **Biometeorological Hazard Evaluation:** Evaluating combined temperature-humidity metrics (NOAA Heat Index) against physiological stress thresholds to identify critical risks to municipal infrastructure, outdoor worker safety, and electrical grid demand.
* **Extreme Event Attribution Disaggregation:** Determining whether extreme temperature days occurring during Ramadan represent genuine localized heatwaves or statistical artifacts generated by rapid seasonal shifts across astronomical boundaries.
* **Assessment of Agricultural and Hydrological Impacts:** Evaluating how delayed autumn cooling in high-altitude basins (Isfahan, Tabriz) alters winter snowpack accumulation, crop dormancy, and regional water security.
---

## 4. Data Sources, NASA POWER Archive & Study Design

### 4.1 NASA POWER Archive and Data Models
Meteorological observations were acquired from the **NASA Prediction of Worldwide Energy Resources (POWER)** project via its Agroclimatology (`AG`) API archive. The data synthesize satellite radiometry and numerical atmospheric reanalysis models:
* **MERRA-2 (*Modern-Era Retrospective analysis for Research and Applications, Version 2*):** Produced by NASA’s Global Modeling and Assimilation Office (GMAO), MERRA-2 assimilates space-based and conventional meteorological observations into a global atmospheric model at a native spatial resolution of $0.5^\circ \times 0.625^\circ$.
* **CERES SYN1deg (*Clouds and the Earth's Radiant Energy System*):** Provides surface solar irradiance products based on satellite radiometer measurements gridded at $1.0^\circ \times 1.0^\circ$.

All records were retrieved using Local Solar Time (`time-standard=lst`) in standard metric units.

### 4.2 Geographical Coordinates and Urban Setting Selection
To capture Iran's diverse climatic geography, I selected five urban centers representing distinct elevations, topographies, and Köppen-Geiger climate classifications:

| City | Target Latitude | Target Longitude | Nominal Elevation | Köppen Climate | Physiographic Description |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Bandar Abbas** | $27.19^\circ\text{ N}$ | $56.27^\circ\text{ E}$ | 0–10 m | $BWh / BSh$ | Coastal Persian Gulf; extreme summer maritime heat and high humidity. |
| **Birjand** | $32.86^\circ\text{ N}$ | $59.22^\circ\text{ E}$ | ~1,490 m | $BWk / BSk$ | Eastern continental arid plateau; high diurnal range and winter cold waves. |
| **Isfahan** | $32.65^\circ\text{ N}$ | $51.68^\circ\text{ E}$ | ~1,570 m | $BWk / BSk$ | Central plateau, endorheic Zayanderud basin; dry highland climate. |
| **Rasht** | $37.28^\circ\text{ N}$ | $49.58^\circ\text{ E}$ | -5 to 15 m | $Cfa$ | South Caspian lowlands; humid subtropical, moderate DTR, high annual precipitation. |
| **Tabriz** | $38.08^\circ\text{ N}$ | $46.29^\circ\text{ E}$ | 1,350–1,600 m | $BSk$ | Northwestern intermontane valley, Lake Urmia basin; cold semi-arid with severe winter freezes. |

*(Note: Although 14 additional global cities—including London, Singapore, Oslo, and Svalbard—were processed through the batch cleaning pipeline, detailed multi-year reports were compiled exclusively for these five primary Iranian locations.)*

### 4.3 Observation Periods and Temporal Coverage Discrepancies
While all city reports cite a nominal 13-year study period of **2013–2025**, an audit of the raw dataset files reveals an important discrepancy in temporal coverage:
* **Standard Coverage (Bandar Abbas, Isfahan, Rasht, Tabriz):**  
  Spans **January 1, 2013 to November 25, 2025** ($N = 4,712$ daily observations).
* **Atypical Coverage (Birjand):**  
  The raw file (`POWER_Point_Daily_20130101_20251123_032d86N_059d22E_LST_Birjand.csv`) truncates on **November 23, 2025** ($N = 4,710$ daily observations), terminating two days earlier than the other four cities. This discrepancy occurred because the raw data files were downloaded from the NASA POWER portal on slightly different days, before the latest updates for Birjand had fully propagated in the archive.
* **Terminal Incompleteness (All Cities):**  
  Because records terminate in late November 2025, December 2025 contains zero observations. Consequently, December 2025 is encoded as `NA` in all monthly aggregation tables and statistical trend models.

### 4.4 Parameter Dictionary and Measurement Units
The ingested raw parameters, standardized variable names, and physical units are summarized below:

| Ingested Parameter | Internal Variable | Physical Unit | Thermodynamic Description |
| :--- | :--- | :--- | :--- |
| `T2M` | `temp_air_mean_c` | $^\circ\text{C}$ | Daily mean air temperature at 2 m above surface. |
| `T2M_MAX` | `temp_air_max_c` | $^\circ\text{C}$ | Daily maximum air temperature at 2 m. |
| `T2M_MIN` | `temp_air_min_c` | $^\circ\text{C}$ | Daily minimum air temperature at 2 m. |
| `RH2M` | `humidity_relative_percent`| $\%$ | Daily mean relative humidity at 2 m. |
| `WS2M` | `wind_speed_ms` | $\text{m/s}$ | Daily mean wind speed at 2 m. |
| `WD2M` | `wind_direction_deg` | $\text{Degrees}$ | Daily mean wind direction at 2 m ($0^\circ–360^\circ$). |
| `PRECTOTCORR` | `precip_total_mm` | $\text{mm/day}$ | Bias-corrected total daily precipitation. |
| `PS` | `pressure_surface_kpa` | $\text{kPa}$ | Atmospheric surface pressure. |
| `ALLSKY_SFC_SW_DWN`| `radiation_solar_mj_m2_day`| $\text{MJ/m}^2/\text{day}$ | All-sky surface downward solar shortwave irradiance. |
| `T2MDEW` | `temp_dewpoint_c` | $^\circ\text{C}$ | Daily mean dew/frost point temperature at 2 m. |
| `T2MWET` | `temp_wetbulb_c` | $^\circ\text{C}$ | Daily mean psychrometric wet-bulb temperature at 2 m. |
| `QV2M` | `humidity_specific_gpkg` | $\text{g/kg}$ | Specific humidity at 2 m. |

### 4.5 Reanalysis vs. In-Situ Weather Station Observations
The initial project plan (`requirements.qmd`) proposed using in-situ weather station records from the **Iran Meteorological Organization (IRIMO)**. However, this source was set aside due to limited data access, and NASA POWER was selected instead.

Understanding the difference between reanalysis and surface station data is critical for interpreting the results:
* **Spatial Aggregation:** Reanalysis parameters represent grid-box volumetric averages ($0.5^\circ \times 0.625^\circ$, roughly $50 \times 60\text{ km}$), whereas synoptic stations provide discrete point measurements.
* **Topographic Attenuation:** Reanalysis smooths out microclimates caused by steep local relief (e.g., Mount Sahand near Tabriz or the Alborz mountains behind Rasht).
* **Urban Heat Island (UHI) Attenuation:** Reanalysis data reflect regional atmospheric states rather than localized urban core warming driven by asphalt, concrete, and anthropogenic heat emissions.
* **Continuity vs. Sensor Drift:** Reanalysis provides physically balanced, gap-free time series that avoid the missing records and instrument calibration shifts common in surface meteorological stations.
---

## 5. Data Preprocessing & Hygiene Pipeline

The data preparation workflow is implemented in `preprocessing-scripts.R` (and mirrored in `preprocessing.Rmd`). The pipeline executes eight sequential operations:

### Step 1: Metadata Header Stripping
NASA POWER exports prefix each file with 20 lines of metadata detailing coordinate boundaries, parameter definitions, and model versions. The pipeline skips these lines using `readr::read_csv(dataset_file_path, skip = 20)`.

### Step 2: Handling Sentinel Missing Values
NASA POWER encodes missing, uncalculated, or corrupted data points with the sentinel flag `-999`. The script isolates the time index fields (`YEAR`, `DOY`) and replaces `-999` with `NA` across all meteorological parameters:
```R
exclude_cols <- c("YEAR", "DOY")
my_data[, !colnames(my_data) %in% exclude_cols] <- 
  lapply(my_data[, !colnames(my_data) %in% exclude_cols], 
         function(col) { col[col == -999] <- NA; col })
```

### Step 3: Physical Consistency Checks
To ensure the physical validity of the reanalysis data, the script evaluates the thermodynamic inequality:
$$T_{\text{min}} \le T_{\text{mean}} \le T_{\text{max}}$$
```R
rows <- my_data %>% filter(!(T2M >= T2M_MIN & T2M <= T2M_MAX))
if (nrow(rows) > 0) {
  print("Something is wrong.")
  return(FALSE)
}
```
Across all five study cities, zero records violated this physical constraint.

### Step 4: Complete-Missingness Row Filtering
Observations where every meteorological column is `NA` are purged:
```R
find_na_rows <- apply(is.na(my_data[, !names(my_data) %in% exclude_cols]), 1, all)
idx_of_na_rows <- which(find_na_rows)
if (length(idx_of_na_rows) > 0) {
  my_data <- my_data[-idx_of_na_rows, ]
}
```

### Step 5: Standardized Schema Renaming
Cryptic NASA abbreviations are mapped to descriptive names following `snake_case` conventions (e.g., `T2M` $\rightarrow$ `temp_air_mean_c`, `RH2M` $\rightarrow$ `humidity_relative_percent`, `PRECTOTCORR` $\rightarrow$ `precip_total_mm`).

### Step 6: Temporal Variable Reconstruction
NASA POWER structures time using four-digit `YEAR` and Day-of-Year (`DOY`, 1–366). The pipeline converts these into ISO calendar dates and extracts calendar months:
$$\text{full\_date} = \text{as.Date}(\text{day\_of\_year} - 1, \text{origin} = \text{"YYYY-01-01"})$$
$$\text{month\_number} = \text{lubridate::month}(\text{full\_date})$$

---

## 6. Feature Engineering and Derived Variables

To evaluate physiological heat stress, seasonal cycles, and localized anomalies, I engineered eight primary analytical variables.

### 6.1 Diurnal Temperature Range (DTR)
* **Variable Name:** `temp_range`
* **Mathematical Formula:** $\text{DTR} = T_{\text{max}} - T_{\text{min}}$
* **Unit:** Degrees Celsius ($^\circ\text{C}$).
* **Index Status:** Standard meteorological index.
* **Interpretation and Analytical Purpose:** DTR serves as an indicator of atmospheric moisture buffering and surface radiative cooling. Low DTR values characterize maritime and humid regions (e.g., Rasht and Bandar Abbas), where water vapor absorbs longwave radiation and dampens diurnal swings. High DTR values indicate dry, continental environments (e.g., Birjand and Isfahan), where clear skies facilitate rapid daytime heating and strong nighttime radiative cooling.

### 6.2 Vapor Pressure Deficit (VPD)
* **Variable Name:** `vpd_kpa`
* **Mathematical Formulation (Tetens' Formula):**
  $$e_s(T) = 0.6108 \exp\left(\frac{17.27 T}{T + 237.3}\right)$$
  $$\text{VPD} = e_s(T_{\text{air\_mean}}) - e_s(T_{\text{dewpoint}})$$
* **Unit:** Kilopascals ($\text{kPa}$).
* **Index Status:** Standard biometeorological and physiological formula.
* **Interpretation and Analytical Purpose:** VPD quantifies the difference between the actual moisture content of the air and its saturation capacity at ambient temperature. It measures the evaporative drying capacity of the atmosphere. Elevated VPD values ($>2.5\text{ kPa}$) indicate intense physiological evaporative demand and drought stress, while low VPD values ($<0.5\text{ kPa}$) signify humid, near-saturated conditions that impede human evaporative cooling via perspiration.

### 6.3 NOAA Rothfusz Heat Index (`HI_standard`)
* **Variable Name:** `HI_standard`
* **Unit:** Degrees Celsius ($^\circ\text{C}$).
* **Index Status:** Official National Oceanic and Atmospheric Administration (NOAA) / National Weather Service (NWS) bioclimatic index.
* **Mathematical Implementation:**
  1. Ambient dry-bulb temperature is converted from Celsius to Fahrenheit: $T_f = 1.8 T_c + 32$.
  2. For cold conditions ($T_f \le 40.0\text{ }^\circ\text{F} \approx 4.44\text{ }^\circ\text{C}$), apparent temperature equals ambient temperature: $\text{HI}_f = T_f$.
  3. For mild conditions, the NWS Simple Formula is evaluated:
     $$\text{HI}_{\text{simple}} = 0.5 \left( T_f + 61.0 + 1.2(T_f - 68.0) + 0.094 \times \text{RH} \right)$$
  4. If the average of $\text{HI}_{\text{simple}}$ and $T_f$ is $\ge 80.0\text{ }^\circ\text{F}$ ($26.67\text{ }^\circ\text{C}$), the full 9-parameter Rothfusz polynomial regression is evaluated:
     $$\begin{aligned}
     \text{HI}_{\text{roth}} = &-42.379 + 2.04901523 T_f + 10.14333127 \text{RH} - 0.22475541 T_f \text{RH} \\
     &- 0.00683783 T_f^2 - 0.05481717 \text{RH}^2 + 0.00122874 T_f^2 \text{RH} \\
     &+ 0.00085282 T_f \text{RH}^2 - 0.00000199 T_f^2 \text{RH}^2
     \end{aligned}$$
  5. **Adjustments:**
     * *Low Relative Humidity Adjustment:* If $\text{RH} < 13\%$ and $80 \le T_f \le 112\text{ }^\circ\text{F}$:
       $$\text{Adj}_{\text{low}} = \frac{13 - \text{RH}}{4} \sqrt{\max\left(0, \frac{17 - |T_f - 95|}{17}\right)}$$
       $$\text{HI}_{\text{roth}} = \text{HI}_{\text{roth}} - \text{Adj}_{\text{low}}$$
     * *High Relative Humidity Adjustment:* If $\text{RH} > 85\%$ and $80 \le T_f \le 87\text{ }^\circ\text{F}$:
       $$\text{Adj}_{\text{high}} = \left(\frac{\text{RH} - 85}{10}\right) \left(\frac{87 - T_f}{5}\right)$$
       $$\text{HI}_{\text{roth}} = \text{HI}_{\text{roth}} + \text{Adj}_{\text{high}}$$
  6. Final values are converted back to Celsius: $\text{HI}_c = (\text{HI}_f - 32) \times \frac{5}{9}$.
* **Analytical Purpose:** Provides a continuous measure of perceived apparent temperature by accounting for moisture-induced inhibition of evaporative skin cooling.

### 6.4 Filtered Heat Index (`HI_filtered`)
* **Variable Name:** `HI_filtered`
* **Mathematical Definition:**
  $$\text{HI\_filtered} = \begin{cases} \text{HI\_standard}, & \text{if } T_{\text{mean}} \ge 27\text{ }^\circ\text{C} \text{ and } \text{RH} \ge 40\% \\ \text{NA}, & \text{otherwise} \end{cases}$$
* **Unit:** Degrees Celsius ($^\circ\text{C}$).
* **Index Status:** Project-specific threshold filter.
* **Interpretation and Analytical Purpose:** Isolates days where combined heat and humidity pose genuine biometeorological hazards, preventing unphysical apparent temperature calculations in winter regimes.

### 6.5 Thermal Discomfort Delta
* **Variable Name:** `heat_index_rel_temp`
* **Mathematical Formula:** $\Delta T_{\text{thermal}} = \text{HI\_standard} - T_{\text{mean}}$
* **Unit:** Degrees Celsius ($^\circ\text{C}$).
* **Index Status:** Project-specific derived diagnostic variable.
* **Interpretation and Analytical Purpose:** Measures the net impact of atmospheric moisture on perceived temperature: positive values indicate humidity-induced heat stress, zero indicates thermal neutrality, and negative values occur in hyper-arid conditions where rapid evaporative skin cooling makes apparent temperature feel slightly cooler than dry-bulb temperature.

### 6.6 Rolling Statistics Baselines
* **Variable Names:** `rolling_avg_7`, `rolling_avg_30`, `rolling_sd_7`, `rolling_sd_30`
* **Mathematical Formulations (Right-Aligned Moving Windows):**
  $$\overline{T}_{k, t} = \frac{1}{k} \sum_{i=0}^{k-1} T_{t-i} \quad \text{for } k \in \{7, 30\}$$
  $$s_{k, t} = \sqrt{\frac{1}{k-1} \sum_{i=0}^{k-1} \left( T_{t-i} - \overline{T}_{k, t} \right)^2}$$
* **Unit:** Degrees Celsius ($^\circ\text{C}$).
* **Index Status:** Standard time-series smoothing operators (via `zoo::rollmean` and `zoo::rollapply`).

### 6.7 Temperature Anomaly Variables and Pipeline Note
* **Variable Names in Script:** `temp_anomaly`, `hi_anomaly`
* **Mathematical Formulations:**
  * *Rolling Anomaly:* $\text{Anom}_{\text{roll}} = T_{\text{mean}} - \overline{T}_{30}$
  * *Day-of-Year Climatological Anomaly:* $\text{Anom}_{\text{DOY}} = T_{\text{mean}} - \mu_{T}(\text{DOY})$
* **Pipeline Audit Note:** In `preprocessing-scripts.R` (lines 189–190), `temp_anomaly` is first computed relative to the 30-day rolling mean, but is immediately overwritten on the next line by the Day-of-Year climatological anomaly. Because `temp_anomaly` was an intermediate variable not directly referenced in the downstream `visualization.Rmd` scripts, this overwrite caused zero downstream errors or distortions in the charts, summary CSV exports, or final reports.

### 6.8 Rolling Extreme Hot and Cold Indicators
* **Variable Names:** `is_extreme_hot`, `is_extreme_cold`
* **Mathematical Formulas:**
  $$\text{is\_extreme\_hot} = T_{\text{mean}} > (\overline{T}_{30} + 2 \times s_{30})$$
  $$\text{is\_extreme\_cold} = T_{\text{mean}} < (\overline{T}_{30} - 2 \times s_{30})$$
* **Unit:** Boolean flag (`TRUE` / `FALSE`).
* **Index Status:** Project-specific statistical anomaly threshold ($2\sigma$ rolling threshold).
---

## 7. Ramadan Date Identification (Kuwaiti Algorithm)

### 7.1 Mathematical Implementation
To automate the classification of Ramadan dates across 13 years without manual lookups, I implemented the **Kuwaiti algorithm** in `preprocessing-scripts.R` as `is_ramadan_kuwaiti(date)`:

```R
is_ramadan_kuwaiti <- function(date) {
  d <- as.Date(date)
  jd <- as.numeric(d) + 2440588
  epoch <- 1948084
  z <- jd - epoch
  cyc <- floor(z / 10631)
  z <- z - 10631 * cyc
  j <- floor((z - 0.133333) / (10631 / 30))
  iy <- 30 * cyc + j
  z <- z - floor(j * (10631 / 30) + 0.133333)
  im <- floor((z + 28.5001) / 29.5)
  if (im == 13) im <- 12
  m <- im
  y <- iy + 1
  return(m == 9)
}
```

The algorithm relies on the tabular arithmetic cycle of 30 lunar years (totalling 10,631 days), where odd-numbered months (including Month 9, Ramadan) are assigned a fixed length of 30 days. Across the 13 Gregorian years of the study period (2013–2025), this arithmetic model produces exactly $13 \times 30 = 390$ Ramadan days in every city dataset.

### 7.2 Tabular Calculation vs. Lunar Crescent Sighting
Using an arithmetic algorithm rather than regional moon-sighting records provides a deterministic, fully reproducible function. However, in practice, religious calendars in Islamic countries—including Iran (governed by the Supreme Leader’s Moon Sighting Committee)—rely on local observational crescent sightings (*ru'yat al-hilal*). The tabular model can diverge by 1 to 2 days from official national calendar dates. For long-term multi-year trend analysis across 13 years, a 1- or 2-day offset introduces negligible bias into decadal regression slopes.

---

## 8. Exploratory Data Analysis and Visualization Strategy

The exploratory visualization framework in `visualization-scripts.R` (documented in `visualization.Rmd`) structures discovery into eight analytical procedures:

1. **Long-Term Daily Temperature Trajectories and LOESS Smoothing:**  
   Daily mean air temperatures (`temp_air_mean_c`) are displayed as a continuous background time series with an overlaid Local Polynomial Regression fitting curve (`loess`, span = 0.4). This non-parametric smoother extracts multi-year baseline dynamics and inter-annual thermal drift from daily weather noise.
2. **Seasonal Temperature Variation and Annual Cycles:**  
   Daily temperatures are plotted across Day-of-Year to display the standard annual sinusoidal curve, establishing baseline rates of spring warming and autumn cooling.
3. **Ramadan-Highlighted Annual Time Series:**  
   Annual calendar plots display daily temperatures with an overlaid red line segment for days where `is_ramadan == TRUE`, contextualizing where Ramadan fell relative to the solar season.
4. **Multi-Variable Biometeorological Assessment:**  
   Parallel diagnostic charts evaluate relative humidity, wind speed, dew point, diurnal temperature range, vapor pressure deficit, Heat Index, and thermal discomfort delta during fasting periods.
5. **Comparisons Among Recent Years (2021–2025):**  
   Multi-line seasonal overlays compare daily temperature paths across recent years to identify short-term inter-annual variability during spring Ramadan iterations.
6. **End-of-Ramadan Temperature Benchmarking:**  
   Extracts the 30-day backward-looking moving average ($\overline{T}_{30}$) on the final day of Ramadan for each year (2014–2025) and compares it against historical temperatures observed on that exact calendar date across all preceding years.
7. **Monthly Decadal Heat Index Regressions:**  
   Daily observations are aggregated into monthly means ($\overline{\text{HI}}_{m, y}$) across each calendar month over the 13-year series, fitting OLS regressions and Mann–Kendall rank tests.
8. **Extreme Thermal Day Distributions & Proportions:**  
   Grouped bar charts and summary CSV tables evaluate the monthly clustering of extreme days and measure Ramadan extreme event occurrences.

---

## 9. Statistical Methods & Decision Framework

### 9.1 Ordinary Least Squares (OLS) Linear Regression
For each calendar month ($m \in \{1, \dots, 12\}$), a univariate linear regression model is fitted across the 13-year series:
$$\overline{\text{HI}}_{m, y} = \beta_0 + \beta_1 \cdot \text{year}_y + \varepsilon_y$$
Extracting the annual warming rate $\beta_1$ (°C/year), $p$-value (`lm_p`), and $R^2$. Cumulative decadal change is calculated as $\Delta \text{HI}_{\text{total}} = 12 \times \beta_1$.

### 9.2 Mann–Kendall Non-Parametric Rank Test
To test for monotonic trends without normal assumptions, I evaluated the Mann–Kendall test via `Kendall::MannKendall()`, deriving Kendall's $\tau$ (`mk_tau`) and non-parametric $p$-value (`mk_p`).

### 9.3 Trend Classification Decision Framework
* **Significant Increasing Trend:** $\beta_1 > 0$ and $\text{mk\_p} \le 0.05$.
* **Significant Decreasing Trend:** $\beta_1 < 0$ and $\text{mk\_p} \le 0.05$. *(Zero instances observed).*
* **No Significant Trend:** $\text{lm\_p} > 0.05$ and $\text{mk\_p} > 0.05$.
* **Weak or Oscillating Trend:** All discordant combinations (e.g., $\text{lm\_p} \le 0.05$ but $\text{mk\_p} > 0.05$).

### 9.4 Rolling-Window Threshold-Based Extreme Detection
Extreme hot and cold days are identified using a $2\sigma$ threshold relative to a 30-day backward-looking moving window ($\overline{T}_{30} \pm 2 s_{30}$).

### 9.5 Ramadan Extreme-Day Metric Definitions
To prevent confusion between distinct analytical questions, I define and report two separate Ramadan extreme-day metrics:

* **Metric 1: Within-Ramadan Extreme Day Rate (%)**  
  $$\text{Within-Ramadan Extreme Rate} = \frac{\text{Extreme Days in Ramadan}}{\text{Total Days in Ramadan (390)}} \times 100$$  
  *Measures how frequently extreme thermal conditions occurred during Ramadan itself.* Saved in the `<city>_calculate percentage of extreme days during Ramadan.csv` files.
* **Metric 2: Ramadan Share of Annual Extreme Days (%)**  
  $$\text{Ramadan Share of Annual Extremes} = \frac{\text{Extreme Days in Ramadan}}{\text{Total Annual Extreme Days Across All 12 Months}} \times 100$$  
  *Measures the proportion of the city's total annual extreme weather that coincided with Ramadan.* Discussed in the narrative text of the PDF reports and visualized in Figure 19.
---

## 10. Systematic Five-City Comparative Results & Synthesis

### Table 1: Climatological and Geographical Baseline
| City | Elevation | Köppen Climate | Multi-Year Baseline Dynamics (LOESS) | Summer Peak Mean Temp | Winter Trough Mean Temp |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Bandar Abbas** | 0–10 m | $BWh / BSh$ | Rose from 26.0 °C (2013) to ~28.0 °C (2024), rising toward 31.0 °C in late 2025 | 36.0 °C to 38.5 °C | 14.0 °C to 18.0 °C |
| **Birjand** | ~1,490 m | $BWk / BSk$ | Fluctuated at 13.0–14.3 °C, rising toward 17.5 °C in late 2025 | 28.0 °C to 30.0 °C | -5.0 °C to -9.0 °C (-14.0 °C in 2023) |
| **Isfahan** | ~1,570 m | $BWk / BSk$ | Stabilized at 16.0–17.5 °C, rising toward 20.8 °C in late 2025 | > 34.0 °C | -5.5 °C |
| **Rasht** | -5 to 15 m | $Cfa$ | Stabilized at 17.0–18.0 °C, rising toward 20.0 °C in late 2025 | 31.0 °C to 32.0 °C | -1.5 °C |
| **Tabriz** | 1,350–1,600 m | $BSk$ | Stabilized at 9.5–10.5 °C, rising toward 14.5 °C in late 2025 | 29.0 °C to 30.0 °C | -16.0 °C to -17.0 °C |

---

### Table 2: Complete Monthly Statistical Trend Summary of Heat Index (2013–2025)
*Data extracted from verified statistical summary CSV files. December models reflect $N=12$ (2013–2024).*

| City | Month | OLS Slope (°C/yr) | 12-Year Change (°C) | OLS $p$ (`lm_p`) | MK $p$ (`mk_p`) | Kendall $\tau$ | Trend Classification |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Bandar Abbas** | **June** | **+0.2903** | **+3.48** | **0.0059** | **0.0060** | **+0.590** | **Significant increasing trend** |
| | **July** | **+0.2851** | **+3.42** | **0.0029** | **0.0060** | **+0.590** | **Significant increasing trend** |
| | **August** | **+0.2753** | **+3.30** | **0.0053** | **0.0327** | **+0.462** | **Significant increasing trend** |
| | September | +0.2376 | +2.85 | 0.0418 | 0.0995 | +0.359 | Weak or oscillating trend |
| | **November** | **+0.2684** | **+3.22** | **0.0038** | **0.0041** | **+0.615** | **Significant increasing trend** |
| **Birjand** | **July** | **+0.1505** | **+1.81** | **0.0080** | **0.0240** | **+0.487** | **Significant increasing trend** |
| | **November** | **+0.2950** | **+3.54** | **0.0098** | **0.0240** | **+0.487** | **Significant increasing trend** |
| | April | +0.1869 | +2.24 | 0.2218 | 0.5022 | +0.154 | No significant trend |
| **Isfahan** | **November** | **+0.3316** | **+3.98** | **0.0038** | **0.0124** | **+0.538** | **Significant increasing trend** |
| | April | +0.1698 | +2.04 | 0.2198 | 0.5830 | +0.128 | No significant trend |
| | October | +0.1340 | +1.61 | 0.1389 | 0.0995 | +0.359 | No significant trend |
| **Rasht** | April | +0.2487 | +2.98 | 0.0336 | 0.1606 | +0.308 | Weak or oscillating trend |
| | October | +0.1955 | +2.35 | 0.0377 | 0.0769 | +0.385 | Weak or oscillating trend |
| | **November** | **+0.3553** | **+4.26** | **0.0124** | **0.0240** | **+0.487** | **Significant increasing trend** |
| | December | +0.2608 | +3.13 | 0.0786 | 0.1926 | +0.303 | No significant trend |
| **Tabriz** | **October** | **+0.2181** | **+2.62** | **0.0216** | **0.0441** | **+0.436** | **Significant increasing trend** |
| | **November** | **+0.2792** | **+3.35** | **0.0071** | **0.0087** | **+0.564** | **Significant increasing trend** |
| | December | +0.3130 | +3.76 | 0.0466 | 0.2437 | +0.273 | Weak or oscillating trend |

---

### Table 3: Cross-City Ramadan Extreme Event Assessment (Dual Metric Comparison)
| City Name | Total Ramadan Days | Extreme Ramadan Days | **Metric 1: Within-Ramadan Extreme Rate** (CSV File) | Total Full-Year Extremes | **Metric 2: Ramadan Share of Annual Extremes** (Report Text) | Peak Year for Ramadan Extremes |
| :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **Bandar Abbas** | 390 | 45 | **11.5%** | 482 | **9.3%** | 2017 (8 days; 20.5% of 2017 extremes) |
| **Tabriz** | 390 | 38 | **9.7%** | 460 | **8.3%** | 2024 (7 days; 20.0% of 2024 extremes) |
| **Isfahan** | 390 | 34 | **8.7%** | 454 | **7.5%** | 2018 (9 days; 21.4% of 2018 extremes) |
| **Rasht** | 390 | 23 | **5.9%** | 386 | **6.0%** | 2025 (7 days; 21.2% of 2025 extremes) |
| **Birjand** | 390 | 19 | **4.9%** | 353 | **5.4%** | 2018 (4 days; 12.5% of 2018 extremes) |

---

### 10.1 Synthesis of Comparative Cross-City Patterns
1. **The Universal November Warming Signal:**  
   Across all five climatically diverse urban centers, **November exhibits statistically significant warming** (OLS $p < 0.05$ and Mann–Kendall $p < 0.05$, with $\tau \ge +0.487$). Estimated cumulative warming over the 12-year interval ranges from $+3.22^\circ\text{C}$ in Bandar Abbas to $+4.26^\circ\text{C}$ in Rasht. This consistent signal delays autumn cooling across all geographic regions.
2. **Summer Thermal Divergence:**  
   Statistically significant summer warming is confined to coastal Bandar Abbas (June, July, August warming at $+0.275$ to $+0.290^\circ\text{C}/\text{year}$) and arid Birjand (July warming at $+0.151^\circ\text{C}/\text{year}$). In contrast, summer Heat Index trends in Isfahan, Rasht, and Tabriz showed no statistically significant monotonic increases ($p > 0.05$).
3. **Humidity-Induced Thermal Discomfort Contrasts:**  
   Coastal Bandar Abbas experiences compounding heat and humidity (Heat Index values frequently reaching 42 °C to 47.5 °C, creating an apparent temperature 8 °C to 12 °C warmer than ambient air). In contrast, arid plateau environments (Birjand, Isfahan) exhibit negative Thermal Discomfort Deltas, where low relative humidity aids sweat evaporation and moderates perceived heat stress.

---

## 11. Discussion: Ramadan Thermal Dynamics & Biometeorology

### 11.1 Evaluating the Ramadan Thermal Tolerability Hypothesis
The primary motivation of the CLIMETR project was to determine whether weather conditions during Ramadan are more thermally tolerable than during the rest of the year. 

The empirical findings indicate that **meteorological conditions during Ramadan are governed by its alignment with the solar calendar**:

1. **Absence of Unique Microclimatic Moderation:** Across all five cities and 13 years of records, there is no empirical evidence of a localized atmospheric moderation unique to Ramadan. Observed daily temperatures and Heat Index values strictly follow the broader astronomical seasons.
2. **The Impact of Lunar Calendar Drift:** Because the Hijri lunar year is roughly 10 to 12 days shorter than the Gregorian solar year, Ramadan moves through all four seasons over a 33-year cycle. During the 2013–2016 period, Ramadan occurred in mid-summer (July/August), coinciding with peak annual temperatures and intense heat stress in Bandar Abbas and Isfahan ($T_{\text{max}} > 38.0\text{ }^\circ\text{C}$). Conversely, during the 2021–2025 cycles, Ramadan occurred in late winter and early spring (February–April), characterized by milder daytime temperatures and cooler nights.
3. **Variable End-of-Ramadan Departures (2025):** Comparing the 30-day rolling mean on the final day of Ramadan 2025 against historical means for that calendar date reveals mixed, localized departures: positive anomalies in Bandar Abbas ($+1.12$ °C), Tabriz ($+1.07$ °C; noted as $3.93^\circ\text{C}$ vs $2.86^\circ\text{C}$ historical baseline), and Rasht ($+0.38$ °C); a near-zero anomaly in Isfahan ($-0.02$ °C); and a negative anomaly in Birjand ($-0.43$ °C).

### 11.2 Distinguishing Temperature, Apparent Indices, and Human Comfort
Ambient air temperature alone does not define human thermal comfort. While dry-bulb temperature measures sensible heat, perceived comfort depends strongly on ambient moisture. In Bandar Abbas, high relative humidity suppresses sweat evaporation, creating extreme apparent thermal stress. In contrast, in arid Birjand and Isfahan, low humidity aids evaporative cooling. Furthermore, empirical heat indices are proxies and do not measure direct physiological responses (e.g., core body temperature, hydration) or agronomic impacts.

---

## 12. Limitations & Methodological Audit

1. **Data Coverage Asymmetry:** Datasets for Bandar Abbas, Isfahan, Rasht, and Tabriz span January 1, 2013 to November 25, 2025 ($N = 4,712$ rows), while Birjand spans January 1, 2013 to November 23, 2025 ($N = 4,710$ rows) because the raw data files were downloaded on slightly different days before NASA POWER's latest updates had fully propagated for Birjand. December 2025 is absent across all cities.
2. **Phase-Lag Artifacts in Rolling Extremes:** Defining extreme days using a right-aligned $30$-day backward-looking moving window ($\overline{T}_{30} \pm 2 s_{30}$) creates phase-lag artifacts during transitional seasons. Autumn temperature drops cause normal seasonal cooling to be misclassified as "extreme cold" days (e.g., 78 cold days in November in Bandar Abbas; 63 in Isfahan).
3. **Out-of-Domain Heat Index Application:** Evaluating the NOAA Rothfusz Heat Index in sub-zero winter regimes produces unphysical values (e.g., $-5.12^\circ\text{C}$ in Tabriz in January 2022). Future cold-season work should utilize the Universal Thermal Climate Index (UTCI).
4. **LOESS Boundary Runaway:** The terminal upward surge in LOESS curves in late 2025 is a mathematical edge artifact driven by asymmetric boundary kernels and missing December data, rather than accelerating climate change.
5. **Multiple Testing:** Evaluating 60 simultaneous hypothesis tests at $\alpha = 0.05$ without False Discovery Rate (FDR) adjustments introduces a non-negligible risk of Type I errors.

---

## 13. Conclusions & Future Research Directions

### 13.1 Summary Conclusions
1. **Rejection of Unique Microclimatic Moderation During Ramadan:** Ambient thermal conditions during Ramadan are governed entirely by astronomical calendar drift through solar seasons.
2. **Universal November Warming:** A statistically significant November warming signal ($+0.268$ to $+0.355^\circ\text{C}/\text{year}$, cumulative $+3.22$ to $+4.26^\circ\text{C}$) is present across all five study locations.
3. **Summer Thermal Divergence:** Summer warming is confined to southern coastal (Bandar Abbas) and eastern arid (Birjand) locations.

### 13.2 Proposed Codebase Enhancements
1. Transition from right-aligned rolling windows to **31-day centered moving windows** or fixed 30-year WMO normals (1991–2020).
2. Integrate the **Universal Thermal Climate Index (UTCI)** for winter regimes.
3. Implement False Discovery Rate (Benjamini–Hochberg) corrections across multi-monthly trend models.
4. Automate programmatic data acquisition via the `nasapower` R client.

---

## 14. References & AI Transparency Declaration

### References
1. **National Oceanic and Atmospheric Administration (NOAA) / National Weather Service (NWS).** (1979). *The Heat Index Equation*. Technical Attachment, SR 90-23. (Rothfusz, L. P., 1990).
2. **Tetens, O.** (1930). *Über some meteorological concepts*. Zeitschrift für Geophysik, 6: 297–309.
3. **NASA Prediction of Worldwide Energy Resources (POWER).** *Agroclimatology Daily Data Archive*. National Aeronautics and Space Administration, Langley Research Center.
4. **Gelaro, R., et al.** (2017). *The Modern-Era Retrospective Analysis for Research and Applications, Version 2 (MERRA-2)*. Journal of Climate, 30(14): 5419–5454.
5. **Kendall, M. G.** (1975). *Rank Correlation Methods*. 4th Edition, Charles Griffin, London.
6. **Mann, H. B.** (1945). *Nonparametric Tests Against Trend*. Econometrica, 13(3): 245–259.
7. **Cleveland, W. S.** (1979). *Robust Locally Weighted Regression and Smoothing Scatterplots*. Journal of the American Statistical Association, 74(368): 829–836.
8. **Khosravi, N. A. (dmaon).** (2025). *CLIMETR: Multi-City Climate Analytics GitHub Repository*.

### Declaration of Generative AI and Assisted Technologies
During the preparation of this research and analytical codebase, I employed generative AI platforms (Google Gemini, OpenAI ChatGPT, NotebookLM, and xAI Grok) to support technical drafting, code review and syntax debugging, grammar refinement, and structural reporting suggestions. All generated suggestions and outputs were rigorously reviewed, cross-examined against empirical datasets, and verified against the NASA POWER source records. The author assumes full scientific responsibility for the integrity, methodological rigor, and conclusions presented in this work.
