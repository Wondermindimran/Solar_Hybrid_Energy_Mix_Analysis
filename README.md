# Solar Hybrid Energy Mix Analysis

**A data analytics portfolio project by Muhammad Imran**

[![Tableau Dashboard](https://img.shields.io/badge/Dashboard-Tableau_Public-blue)](https://public.tableau.com/views/SolarHybridEnergyMixAnalysis/EnergyMixOverview?:language=en-US&publish=yes&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)



## Business Problem

The operations manager of a residential hybrid microgrid reports that natural gas generator fuel costs remain significant despite the installation of a solar PV and battery storage system. Management wants to understand the current energy mix, determine how much load the generator is actually covering versus solar and battery, identify why generator use persists in a solar-dominant system, and determine what changes would reduce or eliminate generator dependency.

This analysis covers one full year of hourly HOMER Pro simulation data for a 20-building residential microgrid in Rajshahi, Bangladesh. The analysis uncovers a counterintuitive finding: the system wastes 263.46 MWh of solar energy annually as excess generation while simultaneously running a generator 555 hours per year; direct evidence of battery undersizing rather than insufficient solar capacity.


## Dataset

| File | Rows | Columns | Scenario |
|---|---|---|---|
| original_load.csv | 8,760 | 7 | Baseline; 650 kW load demand |
| 10__more_load.csv | 8,760 | 7 | Scenario; 760 kW load demand (+10%) |

**Source:** Mendeley Data — KU-MG2 Hybrid Microgrid Dataset
https://data.mendeley.com/datasets/js5mtkf5yk/1

**System components:** Solar PV panels + Natural gas generator + Li-ion battery storage + Inverter

**Location:** Padma Residential Area, Rajshahi, Bangladesh (24°22.6'N, 88°37.2'E)

**Simulation tool:** HOMER Pro microgrid optimization software

**Data period:** 1 January 2007 – 31 December 2007 (8,760 hourly readings per file)

**Note:** This dataset is HOMER Pro simulation output used as a proxy for real operational microgrid data. Real hybrid mini-grid operational data from deployed systems is proprietary and not publicly available. The simulation methodology, system parameters, and KPI results are consistent with real-world hybrid microgrid performance characteristics.


## Tools Used

| Tool | Purpose |
|---|---|
| Python 3 (pandas) | Data loading, cleaning, feature engineering, KPI calculation |
| Python (matplotlib, seaborn) | EDA charts and visualisations |
| SQLite + DB Browser | SQL analysis; 15 business queries |
| Tableau Public | Interactive 3-page dashboard |
| VS Code + Jupyter Notebook | Development environment |
| GitHub | Version control and portfolio hosting |


## Key Data Quality Findings

1. **Units row in raw files.** Row index 1 in both CSV files contains measurement units (kW, kWh, %) rather than data. This row must be skipped on load using `skiprows=[1]`. Failure to skip it causes all numeric columns to be read as strings.

2. **Column name inconsistency between files.** The battery column in the 10% more load file contains a typo; `Li-Ion bATTERY Energy Content` with inconsistent capitalisation. Both files were renamed to identical standardised column names during cleaning.

3. **Zero nulls and zero duplicates.** Both files contain exactly 8,760 rows of complete hourly data with no missing values and no duplicate timestamps across any column.

4. **Negligible negative values in excess column.** A small number of excess_kw readings show values of -0.00 (effectively zero). These are floating point rounding artefacts from the HOMER simulation and were left as-is since they are functionally zero.

5. **Both files cover identical date range.** 1 January 2007 00:00 to 31 December 2007 23:00; confirmed as a complete calendar year.


## KPIs Defined and Calculated

| KPI | Formula | Unit | Baseline Result | +10% Load Result |
|---|---|---|---|---|
| Renewable Penetration % | Solar kWh ÷ Total Load kWh × 100 | % | 159.67% | 145.15% |
| Generator Dependency % | Generator kWh ÷ Total Load kWh × 100 | % | 12.18% | 15.23% |
| Excess Generation Rate | Excess kWh ÷ Total Generation kWh × 100 | % | 38.18% | 33.82% |
| Generator Operating Hours | Count of hours where generator kW > 0 | Hours/year | 555 of 8,760 | 716 of 8,760 |
| CO2 Avoided by Solar | Solar kWh × 0.45 kg CO2/kWh ÷ 1000 | Tonnes/year | 288.5 tonnes | 288.5 tonnes |
| CO2 Emitted by Generator | Generator kWh × 0.45 kg CO2/kWh ÷ 1000 | Tonnes/year | 22.01 tonnes | 30.26 tonnes |
| Battery SOC Mean | Average battery_soc across all hours | % | 80.00% | 80.15% |
| Battery SOC Minimum | Minimum battery_soc recorded | % | 20.21% | 20.13% |
| Days with Battery Gap | Days with both daytime excess AND evening generator use | Days/year | 280 of 365 | — |


## Key Findings

1. **The system wastes 38.18% of all generated solar energy.** Solar panels generate 641.06 MWh per year; 59.67% more than the 401.50 MWh annual load. The excess 263.46 MWh is discarded because the battery reaches full charge during peak solar hours and cannot absorb additional energy.

2. **The generator runs exclusively to fill the evening demand gap.** Of 8,760 annual hours, the generator operates just 555 (6.34%). Hour 18 accounts for 266 of those activations with an average output of 72.12 kW. Hour 19 accounts for 175 activations at 41.54 kW. Every other hour contributes fewer than 13 activations. The generator is not a reliability backup; it is an evening gap filler.

3. **On 280 of 365 days, solar energy was wasted during the day while the generator ran that same evening.** These 280 days wasted a combined 207,647.8 kWh of daytime solar while consuming 40,172.5 kWh of generator fuel in the evening, on the same days. This is the definitive evidence of battery undersizing.

4. **A 10% load increase raises generator dependency by 3.04 percentage points.** Generator output increases 37.48% (from 48.92 MWh to 67.25 MWh) despite load increasing only 10%, because higher demand drains the battery more deeply in the evening, requiring earlier and longer generator activation.

5. **The root cause is battery undersizing, not insufficient solar.** Summer shows the highest generator dependency at 15.1% despite having adequate solar irradiance. Winter shows the lowest generator dependency at 10.5% despite lower solar output — because lower winter demand means the battery is less depleted by evening. The system constraint is storage capacity, not generation capacity.


## Recommendations

1. **Quantify the minimum additional battery storage needed to eliminate the evening gap (Immediate).** Average evening load at hour 18 is 89.81 kW. The generator covers approximately 72.12 kW of that. Storage sufficient to deliver 72 kW for 2 hours equals 144 kWh of additional usable battery capacity. This single addition could eliminate the majority of the 555 annual generator hours.

2. **Implement excess energy monitoring and battery utilisation tracking (Short term).** The 263.46 MWh of annual excess generation represents wasted capital investment and clean energy. Real-time monitoring of battery SOC combined with excess generation alerts would allow operators to identify the charging saturation point and plan storage expansion accordingly.

3. **Evaluate battery storage expansion before any generator capacity expansion (Medium term).** Under +10% load growth, generator output increases 37.48% — disproportionate to the 10% demand increase. Expanding battery storage to absorb more daytime solar surplus is a more cost-effective and environmentally beneficial response to load growth than increasing generator capacity or fuel supply.


## Project Structure

```
Project_3_Energy_Mix/
├── data/
│   ├── raw/
│   │   ├── original_load.csv
│   │   └── 10__more_load.csv
│   └── clean/
│       ├── clean_baseline.csv
│       ├── clean_more_load.csv
│       └── clean_combined.csv
├── sql/
│   ├── energy_mix.db
│   └── energy_mix_queries.sql
├── notebooks/
│   └── energy_mix_analysis.ipynb
├── dashboard/
│   └── [Tableau Public link — see badge above]
├── reports/
│   ├── Energy_Mix_Report.docx
│   ├── chart1_monthly_energy_mix.png
│   ├── chart2_hourly_profile.png
│   ├── chart3_soc_heatmap.png
│   ├── chart4_renewable_penetration.png
│   └── chart5_scenario_comparison.png
├── data_dictionary.md
├── assumptions.md
├── requirements.txt
└── README.md
```

---

## How to Reproduce This Analysis

1. Clone this repository
   ```
   git clone https://github.com/Wondermindimran/Solar_Hybrid_Energy_Mix_Analysis.git
   ```

2. Install dependencies
   ```
   pip install -r requirements.txt
   ```

3. Open the notebook
   ```
   cd notebooks
   jupyter notebook energy_mix_analysis.ipynb
   ```

4. Run all cells in order. Clean CSV files are saved to data/clean/ and the SQLite database is created at sql/energy_mix.db.

5. Open sql/energy_mix.db in DB Browser for SQLite and run the queries from sql/energy_mix_queries.sql.

6. Open Tableau Public and connect to data/clean/clean_combined.csv to build or view the dashboard.


## References

1. Islam, M.R. et al. (2022). KU-MG2: A Hybrid Microgrid Dataset from HOMER Pro Simulation. Mendeley Data. https://data.mendeley.com/datasets/js5mtkf5yk/1

2. HOMER Energy. HOMER Pro Microgrid Software. https://www.homerenergy.com/products/pro/index.html

3. IPCC (2014). Emission Factor for Natural Gas Generation: approximately 0.45 kg CO2 per kWh. Fifth Assessment Report, Working Group III.


## Limitations

- HOMER Pro simulation data: not real measured operational readings from a deployed system
- Location is Rajshahi, Bangladesh: irradiance and load patterns reflect South Asian climate, not Nigerian conditions
- Single year of data (2007): no multi-year degradation or climate variation
- Battery model does not capture cell-level degradation over time
- Financial analysis (fuel cost, LCOE, ROI) is outside the scope of this project.


## Author

**Muhammad Imran**
Data Analyst | SQL, Python, Power BI, Tableau | Interest in renewable energy & sustainability analytics.

https://www.linkedin.com/in/muhammad-imran-96318a23b/?lipi=urn%3Ali%3Apage%3Ad_flagship3_detail_base%3BAmVvyhLaR5O%2Fmzll%2FjNVkw%3D%3D

