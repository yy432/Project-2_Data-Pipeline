# Olist E-Commerce Data Pipeline

> **Stack:** Meltano · dbt · BigQuery  
> **Data:** [Olist Brazilian E-Commerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) — 9 CSV files, ~100k orders, 2016–2018

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         DATA PIPELINE                                        │
│                                                                              │
│  CSV Files          Meltano EL           BigQuery Raw        dbt Transform   │
│  ─────────          ──────────           ────────────        ─────────────  │
│  olist_*.csv  ───►  tap-csv        ───►  olist_raw_*   ───►  staging/       │
│                     target-bigquery                          intermediate/   │
│                                                              marts/          │
│                                                               ├─ core/       │
│                                                               ├─ finance/    │
│                                                               └─ marketing/  │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Star Schema Design

```
                        ┌───────────────┐
                        │   dim_date    │
                        │  date_key PK  │
                        └──────┬────────┘
                               │
        ┌──────────────────────┼────────────────────────┐
        │                      │                         │
┌───────┴──────┐    ┌──────────▼──────────┐   ┌────────┴───────┐
│ dim_customers│    │     fct_orders       │   │  dim_products  │
│customer_key  │◄───│  order_id (PK)       │   │ product_key PK │
│ city         │    │  customer_key   (FK) │   │ category       │
│ state        │    │  date_key       (FK) │   │ weight_g       │
│ region       │    │  order_status        │   │ weight_tier    │
│ latitude     │    │  item_count          │   └───────┬────────┘
│ longitude    │    │  order_gross_total   │           │
└──────────────┘    │  total_payment_value │           │
                    │  review_score        │   ┌───────▼────────┐
                    │  delivery_days       │   │  fct_order_    │
                    └─────────────────────┘   │     items      │
                                              │ order_id       │
                              ┌───────────────│ order_item_id  │
                              │               │ product_key FK │
                    ┌─────────┴──────┐        │ seller_key  FK │
                    │  dim_sellers   │◄───────│ customer_key FK│
                    │ seller_key PK  │        │ date_key    FK │
                    │ city / state   │        │ item_price     │
                    │ region         │        │ freight_value  │
                    └────────────────┘        └────────────────┘
```

### Datasets in BigQuery

| Layer | BigQuery Dataset | Materialization | Purpose |
|-------|-----------------|-----------------|---------|
| Raw | `olist_raw_<env>` | Tables (via Meltano) | Exact copy of source CSVs |
| Staging | `olist_marts_<env>_staging` | Views | Type casting, renaming, light transforms |
| Intermediate | *(ephemeral)* | None (CTEs) | Aggregation helpers |
| Marts – Core | `olist_marts_<env>_core` | Tables | Star schema dims + facts |
| Marts – Finance | `olist_marts_<env>_finance` | Tables | Revenue & payment analytics |
| Marts – Marketing | `olist_marts_<env>_marketing` | Tables | LTV, RFM, seller performance |

---

## Project Structure

```
olist_pipeline/
├── meltano.yml                         # Meltano project: plugins, jobs, schedules
├── extract/
│   └── tap_csv_files.json              # tap-csv stream definitions
├── data/                               # CSV files (git-ignored; use prepare_data.py)
├── transform/                          # dbt project root
│   ├── dbt_project.yml
│   ├── packages.yml                    # dbt-utils, dbt_expectations
│   ├── profiles/
│   │   └── profiles.yml                # BigQuery dev/staging/prod targets
│   ├── macros/
│   │   ├── generate_schema_name.sql    # Custom schema routing
│   │   └── brazil_region.sql           # DRY region CASE macro
│   ├── models/
│   │   ├── staging/
│   │   │   ├── sources.yml             # Raw source declarations + freshness
│   │   │   ├── schema.yml
│   │   │   ├── stg_customers.sql
│   │   │   ├── stg_orders.sql
│   │   │   ├── stg_order_items.sql
│   │   │   ├── stg_order_payments.sql
│   │   │   ├── stg_order_reviews.sql
│   │   │   ├── stg_products.sql
│   │   │   ├── stg_sellers.sql
│   │   │   └── stg_geolocation.sql
│   │   ├── intermediate/
│   │   │   ├── int_order_items_summary.sql
│   │   │   ├── int_order_payments_pivoted.sql
│   │   │   └── int_order_reviews_summary.sql
│   │   └── marts/
│   │       ├── core/
│   │       │   ├── schema.yml
│   │       │   ├── dim_customers.sql
│   │       │   ├── dim_sellers.sql
│   │       │   ├── dim_products.sql
│   │       │   ├── dim_date.sql
│   │       │   ├── fct_orders.sql
│   │       │   └── fct_order_items.sql
│   │       ├── finance/
│   │       │   ├── schema.yml
│   │       │   ├── fct_revenue_by_seller.sql
│   │       │   └── fct_payment_analysis.sql
│   │       └── marketing/
│   │           ├── schema.yml
│   │           ├── fct_customer_ltv.sql
│   │           └── fct_seller_performance.sql
│   └── tests/
│       └── singular/
│           ├── assert_no_negative_prices.sql
│           ├── assert_no_orphan_order_items.sql
│           └── assert_payment_items_totals_aligned.sql
├── scripts/
│   └── prepare_data.py                 # Copy CSVs into data/ folder
├── .github/workflows/
│   └── pipeline.yml                    # CI/CD: lint → EL → transform → test
├── .env.example
├── .gitignore
└── requirements.txt
```

---

## Prerequisites

| Tool | Version |
|------|---------|
| Python | ≥ 3.11 |
| Google Cloud SDK | latest |
| BigQuery API | enabled in your GCP project |
| GCP Service Account | `BigQuery Data Editor` + `BigQuery Job User` roles |

---

## Quickstart

### 1. Clone & configure

```bash
git clone <your-repo>
cd olist_pipeline
cp .env.example .env
# Edit .env — fill in BIGQUERY_PROJECT_ID and GOOGLE_APPLICATION_CREDENTIALS
source .env
```

### 2. Install dependencies

```bash
pip install -r requirements.txt
# tap-csv & target-bigquery are Singer plugins — NOT pip packages.
# Meltano installs them from GitHub into .meltano/ virtual envs:
meltano install
```

### 3. Put CSV files in place

```bash
python scripts/prepare_data.py \
  --src /path/to/kaggle/csvs \
  --dst ./data
```

### 4. Run the EL (Extract → Load to BigQuery)

```bash
# Dev environment (default)
meltano run tap-csv target-bigquery

# Specific environment
meltano --environment prod run tap-csv target-bigquery
```

This loads all 9 CSV files into **`olist_raw_dev`** in BigQuery.

### 5. Install dbt packages

```bash
meltano invoke dbt-bigquery deps
```

### 6. Run dbt transformations

```bash
# Full run
meltano invoke dbt-bigquery run

# Staging models only
meltano invoke dbt-bigquery run-staging

# Marts only (after staging exists)
meltano invoke dbt-bigquery run-marts
```

### 7. Run dbt tests

```bash
meltano invoke dbt-bigquery test
```

### 8. Full pipeline in one command

```bash
meltano run el-and-transform
```

---

## dbt Model Reference

### Staging Layer (Views)

| Model | Source Table | Key Transforms |
|-------|-------------|----------------|
| `stg_customers` | `customers` | Normalise city/state casing |
| `stg_orders` | `orders` | Parse timestamps, derive delivery_days, delivery_buffer |
| `stg_order_items` | `order_items` | Compute item_total = price + freight |
| `stg_order_payments` | `order_payments` | Cast types |
| `stg_order_reviews` | `order_reviews` | Sentiment bucketing (positive/neutral/negative) |
| `stg_products` | `products` + `translation` | Join English category, compute volume_cm3 |
| `stg_sellers` | `sellers` | Normalise city/state casing |
| `stg_geolocation` | `geolocation` | Deduplicate ZIPs via avg lat/lng |

### Intermediate Layer (Ephemeral)

| Model | Description |
|-------|-------------|
| `int_order_items_summary` | Order-level roll-up of items: subtotal, freight, counts |
| `int_order_payments_pivoted` | One row per order: payment type flags, installments |
| `int_order_reviews_summary` | Latest review per order |

### Marts Layer (Tables)

#### Core (Star Schema)
| Model | Grain | Description |
|-------|-------|-------------|
| `dim_customers` | customer_unique_id | Customer with geo + Brazil region |
| `dim_sellers` | seller_id | Seller with geo + Brazil region |
| `dim_products` | product_id | Product with English category, weight/volume tiers |
| `dim_date` | date | Calendar 2016–2022, week/month/quarter attributes |
| `fct_orders` | order_id | Central fact — links customers, date; aggregates items+payments+reviews |
| `fct_order_items` | order_id + item_id | Line-item fact — links products, sellers, customers, date |

#### Finance
| Model | Grain | Description |
|-------|-------|-------------|
| `fct_revenue_by_seller` | seller × month × category | Revenue, AOV, customer count |
| `fct_payment_analysis` | payment_type × month | Installment rates, payment mix |

#### Marketing
| Model | Grain | Description |
|-------|-------|-------------|
| `fct_customer_ltv` | customer_unique_id | Lifetime revenue, RFM scores, customer segment |
| `fct_seller_performance` | seller_id | Delivery SLA, review scores, performance tier |

---

## Environment Management

```bash
# Dev (default — fast iteration, smaller quotas)
meltano --environment dev run el-and-transform

# Staging (pre-prod validation)
meltano --environment staging run el-and-transform

# Production
meltano --environment prod run el-and-transform
```

Datasets created per environment:

| Environment | Raw Dataset | Marts Dataset |
|------------|------------|--------------|
| dev | `olist_raw_dev` | `olist_marts_dev_*` |
| staging | `olist_raw_staging` | `olist_marts_staging_*` |
| prod | `olist_raw_prod` | `olist_marts_prod_*` |

---

## Scheduled Runs

The Meltano schedule `daily-el-and-transform` runs at midnight UTC and executes the full `el-and-transform` job. To activate it with the Meltano scheduler:

```bash
meltano schedule list
meltano invoke airflow scheduler   # if using Airflow orchestrator
```

---

## dbt Docs

```bash
meltano invoke dbt-bigquery docs-generate
meltano invoke dbt-bigquery docs-serve
# Open http://localhost:8080
```

---

## Key Business Metrics Available

| Metric | Location |
|--------|----------|
| GMV (Gross Merchandise Value) | `fct_orders.order_gross_total` |
| Net Revenue Proxy | `fct_orders.net_revenue_proxy` |
| On-Time Delivery Rate | `fct_orders.delivery_status` |
| Average Delivery Days | `fct_orders.actual_delivery_days` |
| Customer Lifetime Value | `fct_customer_ltv.lifetime_revenue` |
| RFM Segmentation | `fct_customer_ltv.customer_segment` |
| Seller Performance Tier | `fct_seller_performance.performance_tier` |
| Payment Method Mix | `fct_payment_analysis` |
| Revenue by Category/Region | `fct_revenue_by_seller` |

---

## Contributing

1. Branch from `develop`
2. Run `sqlfluff lint transform/models --dialect bigquery` before pushing
3. All new models require schema.yml documentation + at least `not_null` / `unique` tests on PK columns
4. Open a PR → CI runs lint + `dbt compile` automatically
