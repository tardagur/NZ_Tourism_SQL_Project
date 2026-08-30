/* =====================================================================
   New Zealand Tourism Satellite Account Analysis
   Author: [Your Name]
   Source: Stats NZ, Tourism Satellite Account: Year ended March 2025
           (published 3 March 2026)
           https://www.stats.govt.nz/information-releases/
           tourism-satellite-account-year-ended-march-2025/

   All figures in this project are real, published government statistics.
   Long time series (expenditure/employment: 1999/2000-2025) plus recent
   detail (visitor arrivals, guest nights, employment by industry:
   2022/2023-2025).
   ===================================================================== */

-- ---------------------------------------------------------------------
-- SCHEMA
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS expenditure_by_product;
DROP TABLE IF EXISTS employment_by_industry;
DROP TABLE IF EXISTS visitor_arrivals_by_purpose;
DROP TABLE IF EXISTS visitor_arrivals_by_region;
DROP TABLE IF EXISTS guest_nights;
DROP TABLE IF EXISTS employment_totals;
DROP TABLE IF EXISTS expenditure_by_tourist_type;
DROP TABLE IF EXISTS expenditure_by_component;

CREATE TABLE expenditure_by_component (
    year                        INT PRIMARY KEY,
    direct_value_added_m        NUMERIC(10,1),
    indirect_value_added_m      NUMERIC(10,1),
    imports_sold_to_tourists_m  NUMERIC(10,1),
    gst_paid_m                  NUMERIC(10,1),
    total_expenditure_m         NUMERIC(10,1)
);

CREATE TABLE expenditure_by_tourist_type (
    year                            INT PRIMARY KEY,
    international_expenditure_m     NUMERIC(10,1),
    domestic_expenditure_m          NUMERIC(10,1),
    total_expenditure_m             NUMERIC(10,1),
    total_exports_m                 NUMERIC(10,1),
    international_pct_of_exports    NUMERIC(5,1)
);

CREATE TABLE employment_totals (
    year                        INT PRIMARY KEY,
    directly_employed           INT,
    indirectly_employed         INT,
    total_tourism_employment    INT
);

CREATE TABLE employment_by_industry (
    year               INT,
    industry           VARCHAR(100),
    people_employed    INT,
    PRIMARY KEY (year, industry)
);

CREATE TABLE visitor_arrivals_by_region (
    year        INT,
    region      VARCHAR(50),
    arrivals    INT,
    PRIMARY KEY (year, region)
);

CREATE TABLE visitor_arrivals_by_purpose (
    year        INT,
    purpose     VARCHAR(50),
    arrivals    INT,
    PRIMARY KEY (year, purpose)
);

CREATE TABLE guest_nights (
    year                            INT PRIMARY KEY,
    international_guest_nights_000  NUMERIC(10,1),
    domestic_guest_nights_000       NUMERIC(10,1),
    total_guest_nights_000          NUMERIC(10,1)
);

CREATE TABLE expenditure_by_product (
    category                VARCHAR(50),
    product                 VARCHAR(100) PRIMARY KEY,
    domestic_business_m     NUMERIC(10,1),
    domestic_government_m   NUMERIC(10,1),
    domestic_household_m    NUMERIC(10,1),
    international_m         NUMERIC(10,1),
    total_m                 NUMERIC(10,1)
);



COPY expenditure_by_component 
FROM 'C:/tmp/expenditure_by_component.csv' 
DELIMITER ',' 
CSV HEADER;
COPY expenditure_by_tourist_type FROM 'C:/tmp/expenditure_by_tourist_type.csv' DELIMITER ',' CSV HEADER;
COPY employment_totals FROM 'C:/tmp/employment_totals.csv' DELIMITER ',' CSV HEADER;
COPY employment_by_industry FROM 'C:/tmp/employment_by_industry.csv' DELIMITER ',' CSV HEADER;
COPY visitor_arrivals_by_region FROM 'C:/tmp/visitor_arrivals_by_region.csv' DELIMITER ',' CSV HEADER;
COPY visitor_arrivals_by_purpose FROM 'C:/tmp/visitor_arrivals_by_purpose.csv' DELIMITER ',' CSV HEADER;
COPY guest_nights FROM 'C:/tmp/guest_nights.csv' DELIMITER ',' CSV HEADER;
COPY expenditure_by_product FROM 'C:/tmp/expenditure_by_product.csv' DELIMITER ',' CSV HEADER;



-- Q1: Total tourism expenditure over the last 5 years on record.
SELECT year, total_expenditure_m
FROM expenditure_by_component
ORDER BY year DESC
LIMIT 5;

-- Q2: What share of total tourism expenditure is GST?
-- Business question: how much of "tourism spend" is actually tax, not
-- revenue to operators?
SELECT year, gst_paid_m, total_expenditure_m,
       ROUND(100.0 * gst_paid_m / total_expenditure_m, 1) AS gst_pct_of_total
FROM expenditure_by_component
ORDER BY year DESC
LIMIT 10;

-- Q3: Which industries employ the most tourism workers in the latest year?
SELECT industry, people_employed
FROM employment_by_industry
WHERE year = 2025 AND industry <> 'Total industry'
ORDER BY people_employed DESC;

-- Q3b: Top 10 tourism products/services by total expenditure (year ended
-- March 2024). Business question: where does tourist spending actually go?
SELECT product, total_m
FROM expenditure_by_product
WHERE product NOT LIKE 'Total%' AND product NOT LIKE '%GST%'
ORDER BY total_m DESC
LIMIT 10;


-- Q4: International vs domestic tourism expenditure split over time.
-- Business question: is NZ tourism becoming more or less reliant on
-- international visitors?
SELECT
    year,
    international_expenditure_m,
    domestic_expenditure_m,
    ROUND(100.0 * international_expenditure_m / total_expenditure_m, 1) AS intl_share_pct
FROM expenditure_by_tourist_type
WHERE year >= 2015
ORDER BY year;

-- Q5: Tourism's share of total employment over time.
-- Business question: is the tourism sector growing as a share of the
-- whole economy's workforce, or shrinking?
SELECT
    e1.year,
    e1.total_tourism_employment,
    ROUND(
        100.0 * e1.total_tourism_employment /
        (SELECT total_tourism_employment FROM employment_totals WHERE year = 2000), 1
    ) AS index_vs_2000  -- growth indexed to year 2000 = 100
FROM employment_totals e1
ORDER BY year;

-- Q6: Visitor arrivals recovery by region since the COVID-19 border closures.
-- Business question: which source markets recovered fastest?
SELECT region, year, arrivals
FROM visitor_arrivals_by_region
WHERE region <> 'Total(5)'
ORDER BY region, year;

-- Q6b: Which products rely most heavily on international vs domestic
-- spending? Business question: which sectors are most exposed if
-- international arrivals drop (e.g. a future border disruption)?
SELECT
    product,
    international_m,
    (domestic_business_m + domestic_government_m + domestic_household_m) AS domestic_m,
    ROUND(
        100.0 * international_m /
        NULLIF(international_m + domestic_business_m + domestic_government_m + domestic_household_m, 0), 1
    ) AS international_share_pct
FROM expenditure_by_product
WHERE product NOT LIKE 'Total%' AND product NOT LIKE '%GST%'
ORDER BY international_share_pct DESC;


-- Q7: Year-over-year growth rate in total tourism expenditure using LAG().
WITH yearly AS (
    SELECT year, total_expenditure_m FROM expenditure_by_component
)
SELECT
    year,
    total_expenditure_m,
    LAG(total_expenditure_m) OVER (ORDER BY year) AS prev_year_expenditure,
    ROUND(
        100.0 * (total_expenditure_m - LAG(total_expenditure_m) OVER (ORDER BY year))
        / NULLIF(LAG(total_expenditure_m) OVER (ORDER BY year), 0), 1
    ) AS pct_growth
FROM yearly
ORDER BY year;

-- Q8: Rank source regions by arrivals within each year.
-- Business question: has the ranking of top source markets changed
-- since the pandemic?
WITH regional AS (
    SELECT year, region, arrivals
    FROM visitor_arrivals_by_region
    WHERE region <> 'Total(5)'
)
SELECT
    year, region, arrivals,
    RANK() OVER (PARTITION BY year ORDER BY arrivals DESC) AS rank_in_year
FROM regional
ORDER BY year, rank_in_year;

-- Q9: 3-year rolling average of tourism employment (smoothing short-term
-- volatility, e.g. COVID-era swings) using a window frame.
SELECT
    year,
    total_tourism_employment,
    ROUND(AVG(total_tourism_employment) OVER (
        ORDER BY year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 0) AS rolling_3yr_avg_employment
FROM employment_totals
ORDER BY year;

-- Q10: Each industry's compound growth from 2023 to 2025 using a CTE
-- with self-join on year.
WITH y2023 AS (
    SELECT industry, people_employed AS emp_2023
    FROM employment_by_industry WHERE year = 2023
),
y2025 AS (
    SELECT industry, people_employed AS emp_2025
    FROM employment_by_industry WHERE year = 2025
)
SELECT
    y2023.industry,
    y2023.emp_2023,
    y2025.emp_2025,
    ROUND(100.0 * (y2025.emp_2025 - y2023.emp_2023) / y2023.emp_2023, 1) AS pct_growth_2yr
FROM y2023
JOIN y2025 ON y2023.industry = y2025.industry
WHERE y2023.industry <> 'Total industry'
ORDER BY pct_growth_2yr DESC;

-- Q11: International tourism expenditure as a share of total exports,
-- with a running (cumulative) average using a window function.
SELECT
    year,
    international_pct_of_exports,
    ROUND(AVG(international_pct_of_exports) OVER (
        ORDER BY year ROWS UNBOUNDED PRECEDING
    ), 1) AS cumulative_avg_pct
FROM expenditure_by_tourist_type
ORDER BY year;
