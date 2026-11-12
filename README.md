# CLIMETR: Multi-City Climate Dynamics, Biometeorological Trends, and Thermal Tolerability During Ramadan (2013–2025)

**Author:** Noor Ahmad (dima) Khosravi (dmaon)  
**Repository:** climetr_analysis  
**Series:** Multi-City Climate Analytics Research Monograph  

---

## Overview & Research Motivation

The **CLIMETR** analytical repository explores multi-decadal climatic dynamics, localized warming trends, and seasonal biometeorological conditions across five climatically diverse urban centers in Iran (**Bandar Abbas, Birjand, Isfahan, Rasht, and Tabriz**) over a 13-year observation period (**2013–2025**).

The project originated from a cultural-meteorological inquiry:
> *"Are atmospheric conditions during the Holy Month of Ramadan inherently milder, cooler, or more thermally tolerable than during the rest of the year, or is perceived comfort purely a function of Gregorian seasonal progression?"*

Because the lunar Hijri calendar regresses through the solar Gregorian year by approximately 10 to 12 days annually, Ramadan traverses all four astronomical seasons across a ~33-year cycle. Between 2013 and 2025, Ramadan shifted from mid-summer (July/August) in 2013–2016 to late winter and early spring (February/March) in 2021–2025. 

Using high-resolution daily meteorological reanalysis from the **NASA Prediction of Worldwide Energy Resources (POWER)** archive, this repository implements an end-to-end R pipeline for data hygiene, biometeorological feature engineering (NOAA Rothfusz Heat Index, Vapor Pressure Deficit), lunar calendar algorithmic tagging, non-parametric trend testing (Mann–Kendall), and parametric regression modeling (OLS).

---

## Key Research Findings

1. **Universal November Warming Signal:**  
   Across all five study cities (Bandar Abbas, Birjand, Isfahan, Rasht, Tabriz), November exhibits statistically significant warming (p < 0.05 OLS and Mann–Kendall, with Kendall's rank correlation tau >= +0.487). Cumulative estimated warming over the 12-year step interval ranges from **+3.22 °C in Bandar Abbas** to **+4.26 °C in Rasht**, systematically delaying traditional autumn cooling.
2. **Summer Thermal Divergence:**  
   Statistically significant summer Heat Index warming is geographically confined to coastal Bandar Abbas (June, July, and August warming at +0.275 to +0.290 °C/year) and arid Birjand (July warming at +0.151 °C/year). Summer trends in Isfahan, Rasht, and Tabriz display no statistically significant monotonic increases (p > 0.05).
3. **Humidity-Induced Discomfort Contrasts:**  
   Coastal Bandar Abbas experiences severe compounding heat and humidity, with summer Heat Index values reaching 42.0 °C to 47.5 °C (creating an apparent thermal load 8 °C to 12 °C warmer than dry-bulb air temperature). Conversely, arid plateau environments (Birjand, Isfahan) display negative Thermal Discomfort Deltas, where low relative humidity aids sweat evaporation and moderates perceived heat stress.
4. **Disaggregation of Ramadan Extreme Events:**  
   Statistical extreme temperature days (+/- 2 SD relative to a 30-day rolling baseline) occurring during Ramadan are driven by astronomical calendar rotation across solar seasons rather than intrinsic microclimatic anomalies.

---

## Geographical & Climatological Scope

While the primary research monographs cover five Iranian urban centers representing major Köppen-Geiger climate classifications, the repository's automated batch processing pipeline ingests and cleans data for 19 global cities.

| City Name | Region | Coordinates | Elevation | Köppen Climate | Primary Study Target |
| :--- | :--- | :--- | :---: | :---: | :---: |
| **Bandar Abbas** | Hormozgan | 27.19 N, 56.27 E | 0–10 m | BWh / BSh | **Primary Monograph** |
| **Birjand** | South Khorasan | 32.86 N, 59.22 E | ~1,490 m | BWk / BSk | **Primary Monograph** |
| **Isfahan** | Isfahan | 32.65 N, 51.68 E | ~1,570 m | BWk / BSk | **Primary Monograph** |
| **Rasht** | Gilan | 37.28 N, 49.58 E | -5 to 15 m | Cfa | **Primary Monograph** |
| **Tabriz** | East Azerbaijan | 38.08 N, 46.29 E | 1,350–1,600 m | BSk | **Primary Monograph** |
| *14 Global Cities* | Cairo, Dubai, Riyadh, Ankara, Barcelona, London, Oslo, Svalbard, Moscow, Singapore, Nevada, Mexico City, Rio de Janeiro, Adelaide | Various Global Coordinates | Various | Diverse | Batch Pipeline |

---

## Data Architecture & NASA POWER Parameters

Daily surface meteorological observations were acquired via the **NASA POWER Agroclimatology (AG)** API archive, combining satellite observations and atmospheric reanalysis models:
* **MERRA-2 (*Modern-Era Retrospective analysis for Research and Applications, Version 2*):** Atmospheric variables gridded at 0.5 deg x 0.625 deg.
* **CERES SYN1deg (*Clouds and the Earth's Radiant Energy System*):** Shortwave surface solar irradiance gridded at 1.0 deg x 1.0 deg.

### Ingested & Engineered Parameter Dictionary

| Variable Name | Original Code | Units | Physical / Thermodynamic Description |
| :--- | :--- | :---: | :--- |
| `temp_air_mean_c` | `T2M` | deg C | Daily mean air temperature at 2 m above surface |
| `temp_air_max_c` | `T2M_MAX` | deg C | Daily maximum air temperature at 2 m |
| `temp_air_min_c` | `T2M_MIN` | deg C | Daily minimum air temperature at 2 m |
| `temp_range` | Derived | deg C | Diurnal temperature range (`temp_air_max_c - temp_air_min_c`) |
| `humidity_relative_percent` | `RH2M` | % | Daily mean relative humidity at 2 m |
| `wind_speed_ms` | `WS2M` | m/s | Daily mean wind speed at 2 m |
| `wind_direction_deg` | `WD2M` | Degrees | Daily mean wind direction at 2 m (0–360 deg) |
| `precip_total_mm` | `PRECTOTCORR` | mm/day | Bias-corrected total daily precipitation |
| `pressure_surface_kpa` | `PS` | kPa | Atmospheric surface pressure |
| `radiation_solar_mj_m2_day`| `ALLSKY_SFC_SW_DWN`| MJ/m^2/day | All-sky surface downward solar shortwave irradiance |
| `temp_dewpoint_c` | `T2MDEW` | deg C | Daily mean dew/frost point temperature at 2 m |
| `temp_wetbulb_c` | `T2MWET` | deg C | Daily mean psychrometric wet-bulb temperature at 2 m |
| `humidity_specific_gpkg` | `QV2M` | g/kg | Specific humidity at 2 m |
| `vpd_kpa` | Derived | kPa | Vapor Pressure Deficit (es(T) - es(Tdew)) |
| `HI_standard` | Derived | deg C | NOAA Rothfusz Heat Index (full continuous formulation) |
| `heat_index_rel_temp` | Derived | deg C | Thermal Discomfort Delta (`HI_standard - temp_air_mean_c`) |
| `is_ramadan` | Derived | Boolean | Flagged via Kuwaiti Tabular Lunar Calendar Algorithm |
| `is_extreme_hot` | Derived | Boolean | Daily temperature > RollingMean_30 + 2 * RollingSD_30 |
| `is_extreme_cold` | Derived | Boolean | Daily temperature < RollingMean_30 - 2 * RollingSD_30 |

---

## Repository Structure

```
climetr_analysis/
├── datasets/                                                # Raw & cleaned meteorological datasets
│   ├── POWER_Point_Daily_20130101_20251123_*_Birjand.csv    # Raw NASA POWER exports
│   ├── *_clean_dataset.csv                                  # Preprocessed clean datasets
│   └── *_calculate percentage of extreme days...csv        # Ramadan extreme event metrics
├── docs/                                                    # Quarto markdown & scientific documentation
│   ├── requirements.qmd                                     # Phase 1 project design & NASA parameters
│   ├── preprocessing.qmd                                    # Data preparation & hygiene documentation
│   ├── research-questions.qmd                               # Core analytical questions & formulas
│   └── visualization.qmd                                    # Diagnostic plotting specifications
├── scripts/                                                 # Executable R processing scripts
│   ├── preprocessing-scripts.R                              # Data cleaning & feature engineering pipeline
│   └── visualization-scripts.R                              # Trend plotting & statistical export functions
├── reports/                                                 # Individual urban monographs & summary text
│   ├── Bandar Abbas.pdf                                     # Diagnostic report: Bandar Abbas
│   ├── Birjand.pdf                                          # Diagnostic report: Birjand
│   ├── Isfahan.pdf                                          # Diagnostic report: Isfahan
│   ├── Rasht.pdf                                            # Diagnostic report: Rasht
│   ├── Tabriz.pdf                                           # Diagnostic report: Tabriz
│   └── report.md                                            # Comprehensive multi-city synthesis monograph
└── README.md                                                # Repository documentation landing page
```

---

## Installation & Usage

### Prerequisites
* **R (v4.0.0 or higher)**
* Required R Packages: `tidyverse`, `readr`, `lubridate`, `tibble`, `zoo`, `xts`, `skimr`, `ggplot2`, `Kendall`

### Running the Data Preprocessing Pipeline

To clean the raw NASA POWER datasets and compute engineered biometeorological features:

```R
source("scripts/preprocessing-scripts.R")

# Example: Process a city dataset
clean_data <- preprocess_city_data(
  dataset_file_path = "datasets/POWER_Point_Daily_20130101_20251123_BandarAbbas.csv",
  output_file_path  = "datasets/bandar-abbas_clean_dataset.csv"
)
```

### Running Statistical Modeling & Visualization

To generate monthly trend tables (OLS & Mann–Kendall), extreme event charts, and Ramadan comparative overlays:

```R
source("scripts/visualization-scripts.R")

# Run full visualization & trend testing suite for a city
visualizations(
  dataset_file_path  = "datasets/bandar-abbas_clean_dataset.csv",
  result_export_path = "results/bandar-abbas/",
  city_name          = "Bandar-Abbas"
)
```

---

## License & Citation

This repository is distributed under the **MIT License**.

### Citation
If you utilize the datasets, R scripts, or analytical findings in your research, please cite as follows:

```bibtex
@techreport{khosravi2025climetr,
  author       = {Khosravi, Noor Ahmad (dima)},
  title        = {Multi-City Climate Dynamics, Biometeorological Trends, and Thermal Tolerability During Ramadan (2013–2025)},
  institution  = {GitHub Repository: climetr_analysis},
  year         = {2025}
}
```
