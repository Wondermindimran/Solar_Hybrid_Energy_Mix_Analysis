# Assumptions Log
## Solar Hybrid Energy Mix Analysis

**Author:** Muhammad Imran
**Last updated:** 20-07-2026
**Purpose:** This document records every assumption made during data loading, feature engineering, KPI calculation, and analysis. Each assumption is numbered, evidenced where possible, and states what would change if the assumption were wrong.


## ASSUMPTION 01: Row Index 1 in Both Raw Files Contains Units, Not Data

**Statement:** The second row of both raw CSV files (pandas index 1 after header) contains measurement unit labels (kW, kWh, %) rather than actual data values. This row is excluded from analysis using skiprows=[1] when loading with pd.read_csv().

**Evidence:** Manual inspection of both files in a text editor confirms row 1 reads: Time, kW, kW, kW, kW, kWh, %. These are unit descriptors, not numeric values. Attempting to convert this row to numeric types returns NaN for all columns.

**Cleaning action:** `pd.read_csv(filepath, skiprows=[1])`

**What would change if this assumption is wrong:** If row 1 were actual data, excluding it would lose one hour of readings; reducing the dataset from 8,760 to 8,759 rows. This would cause a minor 0.011% error in all annual aggregations. Given the confirmed presence of unit labels in that row, this is not a concern.


## ASSUMPTION 02: Data Is Hourly, So Each kW Reading Equals kWh for That Hour

**Statement:** Since each row represents exactly one hour, a power reading of X kilowatts (kW) is equivalent to X kilowatt-hours (kWh) of energy delivered during that hour. All energy aggregations (SUM of kW columns) are therefore treated as energy in kWh.

**Evidence:** The datetime column confirms exactly 8,760 rows from 01/01/2007 00:00 to 12/31/2007 23:00; one row per hour for a complete non-leap year (365 days × 24 hours = 8,760 hours). The dataset documentation confirms hourly resolution.

**Formula used throughout:** Total annual energy (kWh) = SUM(power column in kW) × 1 hour

**What would change if this assumption is wrong:** If readings were averaged over periods shorter than one hour (e.g. 15-minute intervals averaged to hourly), the actual energy per row would be the same as stated. If readings were instantaneous snapshots rather than hourly averages, actual energy totals could differ. HOMER Pro simulation output at hourly resolution represents hourly average power, making the kW = kWh equivalence valid.


## ASSUMPTION 03: Natural Gas Emission Factor Is 0.45 kg CO2 per kWh

**Statement:** All CO2 calculations use an emission factor of 0.45 kg CO2 per kWh for natural gas-fired generation.

**Source:** IPCC Fifth Assessment Report (2014), Working Group III. Natural gas combined cycle emission factors range from 0.40 to 0.50 kg CO2/kWh depending on plant efficiency. The midpoint value of 0.45 kg CO2/kWh is applied as a conservative estimate.

**Application:**
- CO2 avoided by solar: SUM(solar_kw) × 0.45 = 288,478.6 kg = 288.5 tonnes per year
- CO2 emitted by generator: SUM(generator_kw) × 0.45 = 22,013.1 kg = 22.01 tonnes per year

**What would change if this assumption is wrong:** If the actual generator has higher efficiency (0.35 kg CO2/kWh), CO2 emitted would be 17.12 tonnes instead of 22.01 tonnes. If lower efficiency (0.55 kg CO2/kWh), it would be 26.90 tonnes. The CO2 avoided figure scales proportionally. The ratio of avoided to emitted (13.1x) would remain similar regardless of the exact emission factor used.


## ASSUMPTION 04 — Renewable Penetration Is Calculated as Solar Only, Not Solar Plus Battery

**Statement:** Renewable penetration percentage is defined as SUM(solar_kw) / SUM(load_kw) × 100. Battery output is not added to the numerator because the battery stores solar energy, it does not generate renewable energy independently. Including battery would double-count energy already captured in the solar generation figure.

**Rationale:** In energy accounting, a battery is a storage device not a generation source. The energy it discharges was originally captured as solar generation in a prior hour. Adding battery discharge to the renewable numerator would count the same solar electrons twice, once when generated and once when discharged.

**Result:** Renewable penetration = 159.67% (baseline). This correctly represents that solar alone generates 59.67% more energy than the load requires, without double-counting battery throughput.

**What would change if this assumption is wrong:** If battery discharge were included, renewable penetration would appear higher but would be misleading. The analytical conclusions about battery undersizing and excess generation would remain identical.


## ASSUMPTION 05: Excess Generation Represents Genuinely Wasted Energy

**Statement:** The excess_kw column represents solar energy that cannot be used by the load or stored in the battery and is therefore discarded. It is treated as waste — not exported to a grid or sold.

**Evidence:** The dataset documentation describes this as "Excess electrical production"; energy the system generates beyond what load and storage can absorb. The HOMER Pro simulation context confirms this is a standalone microgrid with no grid export capability. Excess energy is curtailed at source.

**Impact on findings:** The 263.46 MWh of annual excess is the foundation of Finding 1; that the system wastes 38.18% of all generated energy. If excess could be exported to a grid, it would represent revenue rather than waste, and the recommendation would shift from battery expansion to grid connection evaluation.


## ASSUMPTION 06: The +10% Load Scenario Uses the Same Solar Generation

**Statement:** In the +10% load scenario file, solar generation is identical to the baseline file at 641,063.5 kWh annually. This is expected, the solar panels are the same physical asset in both scenarios. The only variable changed in HOMER Pro was the load demand.

**Verification:** SUM(solar_kw) for both files returns 641,063.5 kWh. Confirmed identical.

**Implication:** All differences between the two scenarios are driven entirely by the 10% load increase; not by any change in solar availability, battery specifications, or generator parameters. This makes the scenario comparison clean and directly interpretable.


## ASSUMPTION 07: Generator Is Powered by Natural Gas, Not Diesel

**Statement:** The generator in this simulation runs on natural gas, not diesel fuel. The dataset documentation confirms "natural gas generator" as the system component.

**Impact on analysis:** The business problem framing uses "generator dependency" rather than "diesel dependency" throughout. The CO2 emission factor used (0.45 kg CO2/kWh) is appropriate for natural gas, not diesel (diesel is approximately 0.70 kg CO2/kWh). Using a diesel emission factor would significantly overstate CO2 emissions from the generator.

**Portfolio note:** The analytical approach; energy mix breakdown, generator dependency KPI, displacement potential analysis; is identical whether the generator uses natural gas, diesel, or any other fuel. The methodology transfers directly to Nigerian diesel-powered mini-grids by changing the emission factor and fuel cost inputs.


## ASSUMPTION 08: The Evening Gap Is Defined as Hours 18 and 19

**Statement:** The primary generator activation window is defined as hours 18 (6pm) and 19 (7pm) based on analysis of the hourly generator activation data.

**Evidence from data:**
- Hour 18: 266 generator activations out of 365 days (72.9% of evenings), average output 72.12 kW
- Hour 19: 175 generator activations (47.9% of evenings), average output 41.54 kW
- All other hours combined: fewer than 13 activations each

These two hours account for the overwhelming majority of all generator use. All other hours show negligible generator activity.

**What would change if this assumption is wrong:** If the generator also ran significantly during other hours, the finding that it is purely an "evening gap filler" would need to be qualified. The data strongly supports this characterisation.


## ASSUMPTION 09: Battery Undersizing Is Defined as Days With Both Daytime Excess and Evening Generator Use

**Statement:** A day is classified as demonstrating battery undersizing when it has both daytime excess generation (hours 6–17) AND evening generator use (hours 18–23) on the same calendar day. These events occurring on the same day is the direct evidence that the battery could not store available solar energy for later use.

**Result:** 280 of 365 days (76.7%) show this pattern — with 207,647.8 kWh of daytime excess and 40,172.5 kWh of evening generator use on those same days.

**What would change if this assumption is wrong:** If a different definition of battery undersizing were used; for example, based on absolute battery capacity rather than operational patterns, the specific number of flagged days would change. The directional finding that the system wastes energy while simultaneously running the generator would remain valid regardless of the threshold used.


## ASSUMPTION 10: HOMER Pro Simulation Output Is a Valid Proxy for Real Operational Data

**Statement:** This analysis uses HOMER Pro simulation output as a representative proxy for real-world hybrid microgrid operational data. The simulation uses real irradiance data for Rajshahi, Bangladesh and a physically realistic system model.

**Rationale:** Real operational data from deployed hybrid mini-grids is proprietary and not publicly available. HOMER Pro is the industry-standard simulation tool used by NREL, the World Bank, Arnergy, Daystar Power, and other leading mini-grid developers for system design, optimization, and financial modeling. Its outputs are considered accurate representations of expected system behavior.

**Limitations of this assumption:**
- Real systems experience equipment faults, partial shading, soiling, and sensor errors that simulations do not model
- Real battery degradation over time reduces capacity; the simulation models a constant battery at full specification
- Real load profiles vary year to year; the simulation uses a fixed synthetic load profile
- The location is Bangladesh, not Nigeria; irradiance patterns and seasonal load variations differ

**How this is disclosed:** The README, assumptions log, and report all clearly state that this is simulation data used as a proxy, with the reason for using simulation data explained.


## ASSUMPTION 11: Battery Rated Capacity Is 1,000 kWh

**Statement:** The maximum observed value of battery_kwh is 1,000.00 kWh, which is treated as the rated capacity of the battery storage system. The minimum observed SOC of 20.21% is consistent with standard Li-ion battery management systems that limit depth of discharge to protect cell longevity.

**Evidence:** battery_kwh reaches exactly 1,000.00 kWh on multiple occasions throughout the year, confirming this is a hard ceiling representing full charge. The relationship battery_soc = battery_kwh / 1000 × 100 holds exactly throughout the dataset.

**What would change if this assumption is wrong:** If the rated capacity were different (e.g. 800 kWh), the SOC percentages in the dataset would not be consistent with the kWh values. The consistent relationship between these two columns across 8,760 rows confirms 1,000 kWh as the rated capacity.
