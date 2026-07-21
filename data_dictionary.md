# Data Dictionary
## Project 3: Solar Hybrid Energy Mix Analysis

**Dataset:** KU-MG2 HOMER Pro Hybrid Microgrid Simulation
**Location:** Padma Residential Area, Rajshahi, Bangladesh
**System:** Solar PV + Natural Gas Generator + Li-ion Battery + Inverter
**Author:** Muhammad Imran
**Last updated:** 19-07-2026


## How to Read This Document

This document defines every column in every file used in this project; the two raw source files, the three clean files produced by the Python notebook, and every derived column added during feature engineering. For each column you will find its plain English meaning, data type, unit, actual value range from this dataset, any cleaning action taken, and why it matters for the analysis.


## RAW SOURCE FILES

### File 1: original_load.csv

**Rows:** 8,761 (8,760 data rows + 1 units row at index 1)
**Columns:** 7
**Scenario:** Baseline; 650 kW daily load demand
**Granularity:** One row = one hourly reading of the entire microgrid system

**Important:** Row index 1 in the raw file contains measurement units (kW, kWh, %) rather than data. This row must be excluded using `skiprows=[1]` when loading with pandas. Failure to do this causes all numeric columns to be read as string type.


### File 2: 10__more_load.csv

**Rows:** 8,761 (8,760 data rows + 1 units row at index 1)
**Columns:** 7
**Scenario:** +10% Load: 760 kW daily load demand
**Granularity:** One row = one hourly reading

**Important:** The battery column in this file contains a typo (`Li-Ion bATTERY Energy Content`)with inconsistent capitalisation. This column was renamed to `battery_kwh` during cleaning to match the baseline file.


## RAW COLUMN DEFINITIONS (Both Files)

### Column 1: Date and Time (renamed to datetime)

**Data type (raw):** String / Object
**Data type (after cleaning):** datetime64
**Format in raw file:** MM/DD/YYYY HH:MM (24-hour format)
**Range:** 01/01/2007 00:00 to 12/31/2007 23:00
**Null values:** 0
**Unique timestamps:** 8,760

**Plain English:** The exact date and hour of each system reading. One reading per hour for the full calendar year 2007. Midnight on 1 January is hour 0, 11pm on 31 December is hour 23.

**Cleaning applied:** `pd.to_datetime(df['datetime'], format='%m/%d/%Y %H:%M')`

**Why it matters:** Every time-based analysis in this project (hourly profiles, monthly aggregations, seasonal comparisons, and battery SOC heatmaps) depends on this column being correctly parsed as datetime type.


### Column 2: Solar Power Output (renamed to solar_kw)

**Data type:** Float
**Unit:** Kilowatts (kW)
**Range:** 0.00 to 340.92 kW
**Mean:** 73.18 kW
**Zero-value hours:** 4,380 (nighttime; exactly half the year as expected)
**Null values:** 0
**Negative values:** 0

**Plain English:** The instantaneous power output of the solar PV array at each hour. Zero during all nighttime hours and during hours with no irradiance. Peaks at 340.92 kW around solar noon on the clearest days of the year. Since the data is hourly, each kW reading directly equals kWh of energy for that hour.

**Why it matters:** This is the primary energy source of the system and the most important column in the analysis. Annual solar generation of 641,063.5 kWh (641.06 MWh) was calculated as the SUM of this column. Renewable penetration percentage is calculated as SUM(solar_kw) / SUM(load_kw) × 100.


### Column 3: Generator Power Output (renamed to generator_kw)

**Data type:** Float
**Unit:** Kilowatts (kW)
**Range:** 0.00 to 147.97 kW
**Mean:** 5.58 kW
**Zero-value hours:** 8,205 of 8,760 (93.66% of the year the generator is off)
**Non-zero hours:** 555 (6.34% of the year)
**Null values:** 0
**Negative values:** 0

**Plain English:** The instantaneous power output of the natural gas generator at each hour. This column is zero the vast majority of the time — the generator only activates 555 hours out of 8,760. When it does run, it is almost exclusively at hours 18 and 19 (6pm to 8pm) to cover the evening demand gap when solar has dropped to zero and the battery alone cannot cover peak load.

**Why it matters:** Generator dependency percentage is calculated from this column; SUM(generator_kw) / SUM(load_kw) × 100 = 12.18% for the baseline. The pattern of when this column is non-zero reveals the evening gap finding that drives the entire project recommendation.

### Column 4: Total Electrical Load Served (renamed to load_kw)

**Data type:** Float
**Unit:** Kilowatts (kW)
**Range:** 1.63 to 149.24 kW
**Mean:** 45.83 kW
**Zero-value hours:** 0 (load is never zero — minimum residential demand is always present)
**Null values:** 0

**Plain English:** The total electrical power demand of the residential area and EV charging station at each hour. This represents what the system must deliver; the combination of all 60 families plus the 10-battery EV charging station. Load never reaches zero because even at night there is always some baseline consumption from appliances, lighting, and the EV chargers.

**Baseline annual total:** 401,500.0 kWh (401.50 MWh); the denominator for all penetration and dependency percentages.

**+10% scenario annual total:** 441,650.0 kWh (441.65 MWh).

**Why it matters:** Every percentage KPI in this project uses this column as the denominator. Errors in this column would distort every headline metric.


### Column 5: Excess Electrical Production (renamed to excess_kw)

**Data type:** Float
**Unit:** Kilowatts (kW)
**Range:** -0.00 to 289.67 kW
**Mean:** 30.08 kW
**Zero-value hours:** 4,512
**Non-zero hours:** 4,248
**Null values:** 0

**Plain English:** The amount of solar energy generated in excess of what the load requires AND what the battery can absorb at each hour. This energy cannot be stored or used — it is effectively discarded by the system. Excess occurs when the battery is already at or near full charge (100% SOC) and solar output exceeds load demand. It represents wasted clean energy and wasted capital investment in solar panels.

**Key finding:** Annual excess of 263,461.3 kWh (263.46 MWh) equals 38.18% of all energy generated. The system wastes more than one-third of its solar production.

**Negative values:** A small number of readings show -0.00 which is a floating point rounding artefact from HOMER Pro simulation. These are functionally zero and were retained without modification.

**Why it matters:** This column is the evidence for the battery undersizing finding. High excess generation during the day, combined with generator activation in the evening, confirms the battery cannot store enough energy to bridge the gap, not that solar is insufficient.


### Column 6: Li-ion Battery Energy Content (renamed to battery_kwh)

**Data type:** Float
**Unit:** Kilowatt-hours (kWh)
**Range:** 202.11 to 1,000.00 kWh
**Mean:** 800.04 kWh
**Null values:** 0

**Plain English:** The actual amount of energy stored in the battery at each hour, measured in kWh. The maximum of 1,000.00 kWh represents the battery at full charge. The minimum of 202.11 kWh represents the battery at its lowest point across the full year; approximately 20% of capacity. The mean of 800.04 kWh (80% of capacity) confirms the battery is well-charged most of the time, with depletion occurring specifically during evening hours.

**Relationship to battery_soc:** battery_kwh = battery_soc / 100 × rated_capacity. With rated capacity of 1,000 kWh, battery_kwh = battery_soc × 10.

**Why it matters:** The minimum of 202.11 kWh (20.21% SOC) reveals that the battery occasionally approaches its minimum state of charge; the point at which the BMS (Battery Management System) would protect cells from deep discharge. These are the hours most likely to trigger generator activation.


### Column 7: Li-ion Battery State of Charge (renamed to battery_soc)

**Data type:** Float
**Unit:** Percentage (%)
**Range:** 20.21% to 100.00%
**Mean:** 80.00%
**Null values:** 0

**Plain English:** The battery's charge level expressed as a percentage of its total capacity. 100% means fully charged. 20.21% is the lowest recorded value; the minimum state of charge reached during the year. The mean of 80.00% confirms the battery spends most of its time well-charged, primarily because solar generation so significantly exceeds load that the battery charges quickly each morning and stays charged through most of the day.

**Interpretation guidance:** SOC above 90% during daytime hours = battery is full and excess generation is being discarded. SOC dropping below 40% in evening hours = battery is depleted and generator activation is imminent or occurring. SOC remaining above 60% through the night = battery adequately carries the overnight load without generator support.

**Why it matters:** This column is used for the battery SOC heatmap; the most visually informative chart in the Tableau dashboard. The heatmap shows the charging and discharging pattern across hours and months simultaneously, making the evening depletion pattern immediately visible.


## DERIVED COLUMNS: Added During Feature Engineering

These columns do not exist in the raw files. They were created in the Python notebook and are present in all three clean CSV files.


### hour

**Data type:** Integer
**Range:** 0 to 23
**Derived from:** datetime.dt.hour

**Plain English:** The hour of the day extracted from the datetime column. Hour 0 is midnight to 00:59. Hour 18 is 6pm to 6:59pm; the most operationally significant hour in this dataset as it is when the generator most frequently activates.


### month

**Data type:** Integer
**Range:** 1 to 12
**Derived from:** datetime.dt.month

**Plain English:** The calendar month as a number. January = 1, December = 12.


### month_name

**Data type:** String
**Unique values:** 12 (January through December)
**Derived from:** datetime.dt.strftime('%B')

**Plain English:** The calendar month as a readable name. Used for chart axis labels and SQL GROUP BY display.


### season

**Data type:** String
**Values:** Winter, Spring, Summer, Autumn
**Derived from:** Month-based classification

**Classification applied:**
- Winter: December, January, February
- Spring: March, April, May
- Summer: June, July, August
- Autumn: September, October, November

**Plain English:** The meteorological season of each reading. Summer shows the highest generator dependency (15.1%) despite having adequate solar irradiance, because higher summer load demand depletes the battery more deeply into evening hours.


### generator_on

**Data type:** Integer (0 or 1)
**Values:** 0 = generator off, 1 = generator running
**Derived from:** (generator_kw > 0).astype(int)
**Total hours flagged as 1:** 555 of 8,760 (baseline)

**Plain English:** A binary flag indicating whether the generator was running during that hour. Used for counting generator activation frequency in SQL queries and for the hourly generator pattern analysis.


### is_daytime

**Data type:** Integer (0 or 1)
**Values:** 0 = nighttime, 1 = daytime
**Derived from:** (hour >= 6) AND (hour <= 18)

**Plain English:** A flag indicating whether the reading falls within solar operating hours. Used to separate daytime excess generation events from nighttime readings and to define the period during which excess generation can logically occur.


### total_gen_kw

**Data type:** Float
**Unit:** Kilowatts (kW)
**Derived from:** solar_kw + generator_kw

**Plain English:** The combined power output of solar and generator at each hour. The denominator for excess generation rate calculation.


### renewable_pct

**Data type:** Float
**Unit:** Percentage (%)
**Derived from:** solar_kw / load_kw × 100

**Plain English:** The percentage of the instantaneous load covered by solar at each hour. Values above 100% mean solar is producing more than the load requires at that moment — the surplus goes to charging the battery or becomes excess. Annual average renewable penetration of 159.67% is calculated as SUM(solar_kw) / SUM(load_kw) × 100.


### generator_dependency_pct

**Data type:** Float
**Unit:** Percentage (%)
**Derived from:** generator_kw / load_kw × 100

**Plain English:** The percentage of the instantaneous load covered by the generator at each hour. Most hours show 0%. Hours 18 and 19 show significant values. Annual generator dependency of 12.18% is SUM(generator_kw) / SUM(load_kw) × 100.


### co2_saved_kg

**Data type:** Float
**Unit:** Kilograms (kg)
**Derived from:** solar_kw × 0.45

**Plain English:** The estimated CO2 emission avoided per hour by generating from solar rather than from the natural gas generator. Uses the IPCC emission factor of 0.45 kg CO2 per kWh for natural gas generation. Annual total: 288,478.6 kg = 288.5 tonnes.


### scenario

**Data type:** String
**Values:** Baseline (650 kW) or +10% Load (760 kW)
**Added to:** Both DataFrames before combining into clean_combined.csv

**Plain English:** A label identifying which load scenario each row belongs to. Used as the primary filter and color dimension in Tableau to separate the two scenarios on comparison charts.


## CLEAN OUTPUT FILES

### clean_baseline.csv

**Rows:** 8,760
**Columns:** 18 (7 original + 11 derived)
**Contents:** Baseline 650 kW scenario with all derived columns added


### clean_more_load.csv

**Rows:** 8,760
**Columns:** 18 (7 original + 11 derived)
**Contents:** +10% load 760 kW scenario with all derived columns added


### clean_combined.csv

**Rows:** 17,520 (8,760 baseline + 8,760 more load)
**Columns:** 19 (18 + scenario label column)
**Contents:** Both scenarios combined into one file with scenario identifier column
**Primary use:** Tableau dashboard data source — single file enabling scenario filter comparison
