"""Phase 7: Audit the generated recommendation dataset for quality issues."""

import sys; from pathlib import Path; sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))
import pandas as pd
import numpy as np
import json
from collections import Counter

ROOT = Path(__file__).resolve().parent.parent.parent
CSV_PATH = str(ROOT / "training_recommendation/datasets/recommendation_dataset.csv")
df = pd.read_csv(CSV_PATH)
print(f"Dataset: {len(df)} rows, {len(df.columns)} columns")
print(f"Columns: {list(df.columns)}")
print()

FEATURE_COLS = [
    "temperature", "humidity", "rainfall", "tree_age", "area_hectare",
    "confidence", "detection_confidence", "disease_history_count",
    "last_treatment_days", "alert_count", "days_since_last_inspection",
    "historical_disease_count", "historical_disease_frequency",
    "density_per_hectare", "priority_score",
    "health_status", "predicted_disease", "detection_prediction",
    "alert_type", "alert_priority", "season", "risk_level",
]
TARGET_LABELS = [
    "priority", "priority_score", "priority_code", "recommended_action",
    "urgency_score", "estimated_loss_pct", "next_check_days",
]

# 1. Missing values analysis
print("=" * 60)
print("MISSING VALUES ANALYSIS")
print("=" * 60)
missing = df.isnull().sum()
missing_pct = (df.isnull().sum() / len(df)) * 100
missing_df = pd.DataFrame({"missing": missing, "pct": missing_pct})
missing_df = missing_df[missing_df["missing"] > 0].sort_values("missing", ascending=False)
if len(missing_df) > 0:
    print(missing_df.to_string())
    print(f"Columns with missing: {len(missing_df)}/{len(df.columns)}")
else:
    print("No missing values found!")
print()

# 2. Label distribution analysis
print("=" * 60)
print("LABEL DISTRIBUTION")
print("=" * 60)
for col in TARGET_LABELS:
    if col in df.columns:
        if pd.api.types.is_string_dtype(df[col]) or pd.api.types.is_object_dtype(df[col]):
            dist = df[col].value_counts()
            print(f"\n[{col}] (categorical, {len(dist)} unique)")
            print(dist.to_string())
        elif pd.api.types.is_numeric_dtype(df[col]):
            print(f"\n[{col}] (numerical)")
            print(f"  Min: {df[col].min():.4f}")
            print(f"  Max: {df[col].max():.4f}")
            print(f"  Mean: {df[col].mean():.4f}")
            print(f"  Std: {df[col].std():.4f}")
            print(f"  Missing: {df[col].isnull().sum()}")
print()

# 3. Feature analysis
print("=" * 60)
print("FEATURE ANALYSIS")
print("=" * 60)
for col in FEATURE_COLS:
    if col not in df.columns:
        print(f"[{col}] MISSING")
        continue
    if pd.api.types.is_string_dtype(df[col]) or pd.api.types.is_object_dtype(df[col]):
        n_unique = df[col].nunique()
        top_vals = df[col].value_counts().head(5)
        missing_c = df[col].isnull().sum()
        print(f"[{col}] CATEGORICAL, unique={n_unique}, missing={missing_c}")
        for v, c in top_vals.items():
            print(f"    {v}: {c} ({c/len(df)*100:.1f}%)")
    elif pd.api.types.is_numeric_dtype(df[col]):
        missing_c = df[col].isnull().sum()
        print(f"[{col}] NUMERICAL, missing={missing_c}")
        print(f"    range=[{df[col].min():.4f}, {df[col].max():.4f}], mean={df[col].mean():.4f}, std={df[col].std():.4f}")
        if missing_c > 0:
            null_idx = df[df[col].isnull()].index[:5].tolist()
            print(f"    missing rows (sample): {null_idx}")
print()

# 4. Data leakage check
print("=" * 60)
print("DATA LEAKAGE CHECK")
print("=" * 60)
print(f"priority_score == urgency_score (should NOT be identical): {(df['priority_score'] == df['urgency_score']).mean()*100:.1f}% identical")

target_num_cols = [c for c in TARGET_LABELS if c in df.columns and pd.api.types.is_numeric_dtype(df[c])]
feature_num_cols = [c for c in FEATURE_COLS if c in df.columns and pd.api.types.is_numeric_dtype(df[c])]
corr = df[feature_num_cols + target_num_cols].corr()
print("\nTop feature-target correlations:")
for t in target_num_cols:
    if t in corr.columns and t in corr.index:
        t_series = corr.loc[:, t].drop(index=t)
        t_series = t_series.sort_values(ascending=False)
        top_3 = t_series.head(3)
        print(f"  [{t}]")
        for feat, val in top_3.items():
            if abs(val) > 0.5:
                print(f"    HIGH: {feat}: {val:.3f}")
            else:
                print(f"    {feat}: {val:.3f}")
print()

# 5. Temporal leakage check
print("=" * 60)
print("TEMPORAL CHECK (by inspection_date)")
print("=" * 60)
if "inspection_date" in df.columns:
    dates = pd.to_datetime(df["inspection_date"])
    print(f"Date range: {dates.min()} to {dates.max()}")
    print(f"Unique dates: {dates.nunique()}")
    date_dist = dates.dt.date.value_counts().sort_index()
    print(f"Most inspections per day: {date_dist.max()}")
    print(f"Days with <10 inspections: {(date_dist < 10).sum()} / {len(date_dist)}")

    # Check if train/val/test split would leak time
    print("\nWould chronological split help?")
    print(f"  Earliest 15% date: {dates.quantile(0.15)}")
    print(f"  Latest 15% date: {dates.quantile(0.85)}")

print()
print("=" * 60)
print("DATASET AUDIT COMPLETE")
print("=" * 60)
