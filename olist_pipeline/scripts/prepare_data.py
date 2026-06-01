#!/usr/bin/env python3
"""
scripts/prepare_data.py
-----------------------
Copies source CSV files into the `data/` directory consumed by tap-csv.
Run once before `meltano run tap-csv target-bigquery`.

Usage:
    python scripts/prepare_data.py --src /path/to/csvs --dst ./data
"""

import argparse
import shutil
from pathlib import Path

CSV_MAP = {
    "olist_customers_dataset.csv":             "olist_customers_dataset.csv",
    "olist_geolocation_dataset.csv":           "olist_geolocation_dataset.csv",
    "olist_orders_dataset.csv":                "olist_orders_dataset.csv",
    "olist_order_items_dataset.csv":           "olist_order_items_dataset.csv",
    "olist_order_payments_dataset.csv":        "olist_order_payments_dataset.csv",
    "olist_order_reviews_dataset.csv":         "olist_order_reviews_dataset.csv",
    "olist_products_dataset.csv":              "olist_products_dataset.csv",
    "olist_sellers_dataset.csv":               "olist_sellers_dataset.csv",
    "product_category_name_translation.csv":   "product_category_name_translation.csv",
}


def main():
    parser = argparse.ArgumentParser(description="Prepare CSV data for tap-csv ingestion")
    parser.add_argument("--src", required=True, help="Directory containing source CSVs")
    parser.add_argument("--dst", default="data",  help="Destination directory (default: ./data)")
    args = parser.parse_args()

    src = Path(args.src)
    dst = Path(args.dst)
    dst.mkdir(parents=True, exist_ok=True)

    copied, missing = 0, []
    for src_name, dst_name in CSV_MAP.items():
        src_path = src / src_name
        dst_path = dst / dst_name
        if src_path.exists():
            shutil.copy2(src_path, dst_path)
            print(f"  ✓  {src_name} → {dst_path}")
            copied += 1
        else:
            missing.append(src_name)
            print(f"  ✗  {src_name} NOT FOUND")

    print(f"\nDone: {copied} copied, {len(missing)} missing.")
    if missing:
        print("Missing files:", missing)
        raise SystemExit(1)


if __name__ == "__main__":
    main()
