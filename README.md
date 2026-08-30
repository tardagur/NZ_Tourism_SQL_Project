# NZ_Tourism_SQL_Project
PostgreSQL analysis of real Stats NZ tourism data — COVID-19 impact, recovery trends, and sector exposure using CTEs and window functions.

# Aotearoa Tourism Economic Impact & COVID-19 Recovery Intelligence Platform

An end-to-end SQL analytics solution quantifying tourism's contribution to the New Zealand economy across a 26-year time horizon. This project transforms raw government economic registries into a normalized relational model featuring COVID-19 shock/recovery tracking and product-level international-demand exposure analysis.

## 📊 Overview

The objective of this platform is to provide public policy analysts and economic stakeholders with granular visibility into tourism's contribution to GDP, employment, and export earnings. By moving beyond headline totals, the system isolates the sector's collapse and recovery through the COVID-19 border-closure period, and quantifies which specific tourism products carry the most exposure to a future international-demand shock.

The project workflow covers the complete analytics pipeline:

- **Data Engineering & ETL:** Parsing and structurally normalizing multi-sheet government Excel registries — including reconciling multi-row wrapped labels and reshaping wide industry-by-year tables into long analytical form — via a Python (openpyxl) extraction pipeline.
- **Relational Data Modeling:** Designing a normalized fact/dimension schema spanning expenditure, employment, visitor-arrival, and product-level domains, with primary-key and referential integrity enforced at load time.
- **Advanced Analytical Layer:** Developing CTE-driven and window-function-based metrics (`LAG`, `RANK`, moving averages, cumulative averages, year-over-year self-joins) for time-series trend and cohort-style analysis.
- **Decision-Oriented Query Design:** Framing every query around a specific economic or policy question — recovery trajectory, market-share shift, sector exposure — rather than raw reporting.

---

## 🛠 Tech Stack & Engineering Architecture

- **Database Engine:** PostgreSQL 16
- **ETL Engine:** Python (`openpyxl`, `csv`)
- **Data Source:** Statistics New Zealand (Stats NZ), *Tourism Satellite Account: Year ended March 2025* (published 3 March 2026)
- **Data Model:** Normalized relational schema — 7 tables across expenditure, employment, visitor-arrival, and product dimensions
- **Version Control:** Git-managed SQL + Python pipeline, reproducible from source `.xlsx` to query-ready database

---

## 🗂 Data Model

```
expenditure_by_component      (year, direct/indirect value added, imports, GST, total)
expenditure_by_tourist_type   (year, international vs domestic expenditure, exports)
expenditure_by_product        (category, product, domestic business/govt/household, international, total)
employment_totals             (year, direct/indirect/total tourism employment)
employment_by_industry        (year, industry, people employed)
visitor_arrivals_by_region    (year, region, arrivals)
visitor_arrivals_by_purpose   (year, purpose, arrivals)
guest_nights                  (year, international/domestic/total guest nights)
```

Time coverage: 1999–2025 for headline expenditure and employment series; 2022–2025 for visitor-arrival and industry-level detail; year ended March 2024 for product-level expenditure detail.

---

## 🔎 Analytical Capabilities

| Layer | Technique | Business Question Answered |
|---|---|---|
| Foundational | Filtering, aggregation, ordering | Where does tourist spending actually go? Which industries employ the most people? |
| Intermediate | Multi-year comparison, percentage-share calculation, subqueries | Is NZ tourism becoming more or less reliant on international visitors? |
| Advanced | CTEs, `LAG`, `RANK`, rolling/cumulative window functions, year-over-year self-joins | How did the sector collapse and recover through COVID-19? Which source markets and industries led the recovery? Which products are most exposed to a future international-demand shock? |

---

## 📈 Key Findings

- **Total tourism expenditure fell 36.2%** in the year to March 2021 (COVID-19 border closures), then **rebounded 41.9%** in the year to March 2023 as borders reopened.
- **Air and space transport employment grew fastest** of all tourism industries (+34.5%) between 2023 and 2025, reflecting the aviation sector's recovery.
- **Oceania (mostly Australia) remained the top source region** throughout the recovery, but **Asia overtook Europe and the Americas** for second place by 2024.
- International tourism's share of total exports **collapsed from ~20% pre-COVID to 2.1% in 2021**, and had only recovered to **17.2% by 2024** — still below pre-pandemic levels.
- **Air passenger transport is the single largest tourism product** ($6.35B, year ended March 2024) — ahead of food & beverage ($4.9B) and accommodation ($3.9B).
- **Education services and other tourism-related services carry the highest international-demand exposure** (55.7% and 65.5% of spend respectively) — the sectors most at risk from a future border disruption.

---

## ▶️ How to Run

```bash
# 1. Extract source data into normalized CSVs
python3 extract_tsa_data.py

# 2. Build the database and run the full analytical suite
createdb tsa_nz
psql -d tsa_nz -f NZ_Tourism_SQL_Analysis.sql
```

**Data integrity note:** all figures are real, published Stats NZ statistics — nothing in this dataset is simulated. 2025 figures are marked provisional (P) by Stats NZ and may be revised in future releases.
