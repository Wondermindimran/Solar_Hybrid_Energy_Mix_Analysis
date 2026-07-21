-- ==========================================================================================
-- Solar Hybrid Energy Mix Analysis
-- SQL Query Bank
-- Author: Muhammad Imran
-- Date: 16-07-2026
-- Dataset: KU-MG2 HOMER Pro Microgrid Simulation
-- Location: Padma Residential Area, Rajshahi, Bangladesh
-- System: Solar PV + Natural Gas Generator + Li-ion Battery
-- Baseline load: 650 kW | Scenario: +10% load (760 kW)
-- Data period: 1 January 2007 – 31 December 2007 (8,760 hours)
-- ==========================================================================================



-- Annual energy totals for the baseline scenario

-- Q01: What is the total annual energy breakdown for the baseline system?
-- Business question: How much energy does each source contribute annually?
-- Concept: SUM aggregation with unit conversion and percentage calculation
-- Note: Data is hourly (kW = kWh per hour), so SUM of kW = total kWh

SELECT
    ROUND(SUM(solar_kw), 1)                                      AS solar_kwh,
    ROUND(SUM(generator_kw), 1)                                  AS generator_kwh,
    ROUND(SUM(load_kw), 1)                                       AS total_load_kwh,
    ROUND(SUM(excess_kw), 1)                                     AS excess_kwh,
    ROUND(SUM(solar_kw) / SUM(load_kw) * 100, 2)                AS renewable_penetration_pct,
    ROUND(SUM(generator_kw) / SUM(load_kw) * 100, 2)            AS generator_dependency_pct,
    ROUND(SUM(excess_kw) / (SUM(solar_kw) + SUM(generator_kw))
          * 100, 2)                                              AS excess_rate_pct
FROM baseline;

---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------


--Monthly energy mix breakdown

-- Q02: How does the energy mix vary across every month of the year?
-- Business question: Which months have highest generator dependency?
-- Concept: GROUP BY month + multiple SUM aggregations

SELECT
    month,
    month_name,
    ROUND(SUM(solar_kw), 1)                               AS solar_kwh,
    ROUND(SUM(generator_kw), 1)                           AS generator_kwh,
    ROUND(SUM(load_kw), 1)                                AS load_kwh,
    ROUND(SUM(excess_kw), 1)                              AS excess_kwh,
    ROUND(SUM(solar_kw) / SUM(load_kw) * 100, 2)         AS renewable_pct,
    ROUND(SUM(generator_kw) / SUM(load_kw) * 100, 2)     AS gen_dep_pct,
    SUM(generator_on)                                     AS generator_hours
FROM baseline
GROUP BY month, month_name
ORDER BY month;

---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------



-- Hourly generation and load profile across the full year

-- Q03: What is the average generation and load pattern across 24 hours?
-- Business question: When exactly does the generator activate and why?
-- Concept: GROUP BY hour + AVG to reveal the daily operational pattern

SELECT
    hour,
    ROUND(AVG(solar_kw), 2)                               AS avg_solar_kw,
    ROUND(AVG(generator_kw), 2)                           AS avg_generator_kw,
    ROUND(AVG(load_kw), 2)                                AS avg_load_kw,
    ROUND(AVG(excess_kw), 2)                              AS avg_excess_kw,
    ROUND(AVG(battery_soc), 2)                            AS avg_battery_soc,
    SUM(generator_on)                                     AS generator_activations,
    ROUND(SUM(generator_kw) / NULLIF(SUM(load_kw), 0)
          * 100, 2)                                       AS gen_share_of_load_pct
FROM baseline
GROUP BY hour
ORDER BY hour;

---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------



-- Generator activation pattern; exactly when and how often does it run?

-- Q04: On how many days did the generator run, and in which hours?
-- Business question: Is generator use predictable or random?
-- Concept: GROUP BY hour with COUNT and percentage of days active

WITH daily_count AS (
    SELECT COUNT(DISTINCT date) AS total_days FROM baseline
)
SELECT
    b.hour,
    COUNT(CASE WHEN b.generator_on = 1 THEN 1 END)        AS hours_generator_ran,
    ROUND(COUNT(CASE WHEN b.generator_on = 1 THEN 1 END)
          * 100.0 / 365, 1)                               AS pct_of_days_active,
    ROUND(AVG(CASE WHEN b.generator_on = 1
              THEN b.generator_kw END), 2)                AS avg_output_when_on_kw,
    ROUND(MAX(b.generator_kw), 2)                         AS peak_output_kw
FROM baseline b, daily_count
GROUP BY b.hour
HAVING hours_generator_ran > 0
ORDER BY hours_generator_ran DESC;



---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------



-- Excess generation analysis; when and how much solar is wasted?

-- Q05: When does excess generation occur and how much is lost each month?
-- Business question: When is the battery full and solar being wasted?
-- Concept: GROUP BY month with conditional aggregation

SELECT
    month,
    month_name,
    COUNT(CASE WHEN excess_kw > 0 THEN 1 END)             AS hours_with_excess,
    ROUND(SUM(excess_kw), 1)                              AS total_excess_kwh,
    ROUND(AVG(CASE WHEN excess_kw > 0
              THEN excess_kw END), 2)                     AS avg_excess_when_occurring_kw,
    ROUND(MAX(excess_kw), 2)                              AS peak_excess_kw,
    ROUND(SUM(excess_kw) / SUM(solar_kw) * 100, 2)        AS pct_solar_wasted,
    ROUND(AVG(CASE WHEN excess_kw > 0
              THEN battery_soc END), 2)                   AS avg_soc_during_excess
FROM baseline
GROUP BY month, month_name
ORDER BY month;

---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------



-- Battery SOC pattern by hour and season

-- Q06: How does battery state of charge vary by hour across seasons?
-- Business question: Does the battery ever run critically low?
-- Concept: GROUP BY hour and season with MIN/AVG aggregation

SELECT
    season,
    hour,
    ROUND(AVG(battery_soc), 2)                            AS avg_soc_pct,
    ROUND(MIN(battery_soc), 2)                            AS min_soc_pct,
    COUNT(CASE WHEN battery_soc < 30 THEN 1 END)          AS hours_below_30pct,
    COUNT(CASE WHEN battery_soc >= 95 THEN 1 END)         AS hours_above_95pct
FROM baseline
GROUP BY season, hour
ORDER BY season, hour;

---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------



-- Load factor analysis by month

-- Q07: What is the load factor for each month?
-- Business question: How efficiently is the system infrastructure being used?
-- Concept: AVG divided by MAX per group

SELECT
    month,
    month_name,
    ROUND(AVG(load_kw), 2)                                AS avg_load_kw,
    ROUND(MAX(load_kw), 2)                                AS peak_load_kw,
    ROUND(MIN(load_kw), 2)                                AS min_load_kw,
    ROUND(AVG(load_kw) / MAX(load_kw) * 100, 2)          AS load_factor_pct,
    ROUND(MAX(load_kw) - AVG(load_kw), 2)                AS peak_to_avg_gap_kw
FROM baseline
GROUP BY month, month_name
ORDER BY month;

---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------



--  Seasonal energy mix comparison

-- Q08: How does the energy mix differ across seasons?
-- Business question: Is the system more generator-dependent in any season?
-- Concept: GROUP BY season with full KPI calculation

SELECT
    season,
    COUNT(*)                                              AS total_hours,
    ROUND(SUM(solar_kw), 1)                              AS solar_kwh,
    ROUND(SUM(generator_kw), 1)                          AS generator_kwh,
    ROUND(SUM(load_kw), 1)                               AS load_kwh,
    ROUND(SUM(excess_kw), 1)                             AS excess_kwh,
    ROUND(SUM(solar_kw) / SUM(load_kw) * 100, 2)        AS renewable_pct,
    ROUND(SUM(generator_kw) / SUM(load_kw) * 100, 2)    AS gen_dep_pct,
    SUM(generator_on)                                    AS generator_hours,
    ROUND(SUM(excess_kw) / SUM(solar_kw) * 100, 2)      AS solar_wasted_pct
FROM baseline
GROUP BY season
ORDER BY gen_dep_pct DESC;

---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------



-- Scenario comparison: baseline vs 10% more load

-- Q09: How does a 10% load increase change the energy mix?
-- Business question: Is the system sized for future demand growth?
-- Concept: UNION ALL to combine both scenarios + comparison

SELECT
    scenario,
    ROUND(SUM(solar_kw), 1)                               AS solar_kwh,
    ROUND(SUM(generator_kw), 1)                           AS generator_kwh,
    ROUND(SUM(load_kw), 1)                                AS load_kwh,
    ROUND(SUM(excess_kw), 1)                              AS excess_kwh,
    ROUND(SUM(solar_kw) / SUM(load_kw) * 100, 2)         AS renewable_pct,
    ROUND(SUM(generator_kw) / SUM(load_kw) * 100, 2)     AS gen_dep_pct,
    SUM(generator_on)                                     AS generator_hours,
    ROUND(SUM(excess_kw) / SUM(solar_kw) * 100, 2)       AS solar_wasted_pct
FROM combined
GROUP BY scenario
ORDER BY scenario;

---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------



-- Month-by-month scenario comparison

-- Q10: Which months are most affected by the 10% load increase?
-- Business question: Where should battery expansion be prioritised seasonally?
-- Concept: GROUP BY scenario and month to show per-month impact

SELECT
    c.scenario,
    c.month,
    c.month_name,
    ROUND(SUM(c.generator_kw), 1)                         AS generator_kwh,
    ROUND(SUM(c.excess_kw), 1)                            AS excess_kwh,
    ROUND(SUM(c.generator_kw) / SUM(c.load_kw) * 100, 2) AS gen_dep_pct,
    SUM(c.generator_on)                                   AS generator_hours
FROM combined c
GROUP BY c.scenario, c.month, c.month_name
ORDER BY c.month, c.scenario;

---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------



-- Identify hours where solar could have replaced generator but did not

-- Q11: How many hours ran the generator when solar was also producing?
-- Business question: Is the generator running unnecessarily during solar hours?
-- Concept: Conditional COUNT with multiple WHERE conditions

SELECT
    hour,
    COUNT(*)                                              AS total_hours_in_year,
    COUNT(CASE WHEN generator_on = 1 
               AND solar_kw > 0 THEN 1 END)              AS gen_running_during_solar,
    COUNT(CASE WHEN generator_on = 1 
               AND solar_kw = 0 THEN 1 END)              AS gen_running_no_solar,
    ROUND(AVG(CASE WHEN generator_on = 1 
                   AND solar_kw > 0
                   THEN solar_kw END), 2)                AS avg_solar_when_both_on_kw,
    ROUND(AVG(CASE WHEN generator_on = 1
                   AND solar_kw > 0
                   THEN battery_soc END), 2)             AS avg_soc_when_both_on
FROM baseline
GROUP BY hour
HAVING gen_running_during_solar > 0
    OR gen_running_no_solar > 0
ORDER BY hour;

---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------



-- Energy balance validation

-- Q12: Does energy generation balance with load plus excess plus battery change?
-- Business question: Is the simulation data internally consistent?
-- Concept: Energy balance check; generation must equal consumption plus losses

SELECT
    month,
    month_name,
    ROUND(SUM(solar_kw) + SUM(generator_kw), 1)          AS total_generation_kwh,
    ROUND(SUM(load_kw) + SUM(excess_kw), 1)              AS total_consumption_kwh,
    ROUND((SUM(solar_kw) + SUM(generator_kw))
          - (SUM(load_kw) + SUM(excess_kw)), 1)          AS balance_error_kwh,
    ROUND(ABS((SUM(solar_kw) + SUM(generator_kw))
          - (SUM(load_kw) + SUM(excess_kw)))
          / (SUM(solar_kw) + SUM(generator_kw))
          * 100, 3)                                       AS balance_error_pct
FROM baseline
GROUP BY month, month_name
ORDER BY month;

---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------



-- CO2 savings and emissions avoided

-- Q13: How much CO2 is avoided by using solar instead of the generator?
-- Business question: What is the environmental value of this system?
-- Concept: Emission factor calculation (natural gas: 0.45 kg CO2 per kWh)

SELECT
    month,
    month_name,
    ROUND(SUM(solar_kw), 1)                               AS solar_kwh,
    ROUND(SUM(generator_kw), 1)                           AS generator_kwh,
    ROUND(SUM(solar_kw) * 0.45, 1)                        AS co2_avoided_kg,
    ROUND(SUM(generator_kw) * 0.45, 1)                    AS co2_emitted_kg,
    ROUND((SUM(solar_kw) * 0.45) / 1000, 2)              AS co2_avoided_tonnes,
    ROUND((SUM(generator_kw) * 0.45) / 1000, 4)          AS co2_emitted_tonnes
FROM baseline
GROUP BY month, month_name
ORDER BY month;

---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------



-- Peak demand analysis and generator sizing check

-- Q14: What is the peak demand profile and is the generator sized correctly?
-- Business question: Can the generator handle worst-case evening demand?
-- Concept: Percentile-based analysis using ORDER BY and LIMIT

WITH evening_demand AS (
    SELECT
        date,
        hour,
        load_kw,
        solar_kw,
        generator_kw,
        battery_soc,
        load_kw - solar_kw                               AS unmet_by_solar_kw
    FROM baseline
    WHERE hour BETWEEN 18 AND 21
),
ranked AS (
    SELECT *,
           RANK() OVER (ORDER BY load_kw DESC)           AS demand_rank
    FROM evening_demand
)
SELECT
    date,
    hour,
    ROUND(load_kw, 2)                                    AS load_kw,
    ROUND(solar_kw, 2)                                   AS solar_kw,
    ROUND(generator_kw, 2)                               AS generator_kw,
    ROUND(battery_soc, 2)                                AS battery_soc_pct,
    ROUND(unmet_by_solar_kw, 2)                          AS gap_solar_must_cover_kw,
    demand_rank
FROM ranked
WHERE demand_rank <= 20
ORDER BY demand_rank;

---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------



-- Battery undersizing evidence: excess during day, generator at night


-- Q15: On the same days, how much solar was wasted during the day AND 
-- how much generator was needed that evening?
-- Business question: Quantify the battery gap — the direct cost of undersizing
-- Concept: Self-join on date comparing daytime excess vs evening generator use

WITH daytime_excess AS (
    SELECT
        date,
        ROUND(SUM(excess_kw), 2)                         AS daily_excess_kwh,
        ROUND(AVG(battery_soc), 2)                       AS avg_daytime_soc
    FROM baseline
    WHERE hour BETWEEN 6 AND 17
    GROUP BY date
),
evening_generator AS (
    SELECT
        date,
        ROUND(SUM(generator_kw), 2)                      AS evening_gen_kwh,
        ROUND(MIN(battery_soc), 2)                       AS min_evening_soc
    FROM baseline
    WHERE hour BETWEEN 18 AND 23
    GROUP BY date
)
SELECT
    d.date,
    d.daily_excess_kwh,
    d.avg_daytime_soc,
    e.evening_gen_kwh,
    e.min_evening_soc,
    ROUND(d.daily_excess_kwh + e.evening_gen_kwh, 2)     AS total_inefficiency_kwh
FROM daytime_excess d
JOIN evening_generator e ON e.date = d.date
WHERE d.daily_excess_kwh > 0
  AND e.evening_gen_kwh > 0
ORDER BY total_inefficiency_kwh DESC
LIMIT 20;

---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
