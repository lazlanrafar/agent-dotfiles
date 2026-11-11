# Data Analysis, Visualization & Pipelines — Python Developer Reference

Sumber: [roadmap.sh/python-data-analysis](https://roadmap.sh/python-data-analysis)

---

## 1. Vectorized Computing dengan NumPy

- **Hindari loop `for` Python pada array numerik**. Gunakan operasi ter-vektorisasi (ufunc) dan broadcasting.
- Gunakan `np.random.default_rng(seed)` (Generator API modern), bukan `np.random.seed()` global legacy.

```python
import numpy as np

rng = np.random.default_rng(42)
data = rng.normal(loc=100.0, scale=15.0, size=(1000, 4))

# Vectorized z-score normalization per kolom (broadcasting)
mean = data.mean(axis=0)
std = data.std(axis=0)
z_scores = (data - mean) / std

# Boolean masking & IQR outlier filtering
q25, q75 = np.percentile(data[:, 0], [25, 75])
iqr = q75 - q25
clean_rows = data[(data[:, 0] >= q25 - 1.5 * iqr) & (data[:, 0] <= q75 + 1.5 * iqr)]
```

---

## 2. DataFrame Manipulation: Polars vs Pandas 2.x

- **Project baru / dataset besar**: Utamakan **Polars** (multi-threaded, lazy execution, ekspresi teroptimasi, berbasis Apache Arrow).
- **Project existing / ekosistem scikit-learn klasik**: Gunakan **Pandas 2.x** dengan backend PyArrow (`dtype_backend="pyarrow"`).
- Hindari `.iterrows()` atau `.apply(..., axis=1)` di Pandas/Polars — selalu gunakan operasi kolom/ekspresi.

```python
import polars as pl

# Lazy query evaluation (pushdown predicate & projection otomatis)
q = (
    pl.scan_parquet("s3://bucket/transactions/*.parquet")
    .filter(pl.col("status") == "completed")
    .with_columns(
        (pl.col("price") * pl.col("qty")).alias("revenue"),
        pl.col("created_at").dt.truncate("1d").alias("day"),
    )
    .group_by("day", "category")
    .agg(
        pl.len().alias("tx_count"),
        pl.col("revenue").sum().alias("total_revenue"),
        pl.col("revenue").quantile(0.95).alias("p95_revenue"),
    )
    .sort("day", descending=True)
)
df = q.collect()
```

### Pandas 2.x Idiomatic Pattern (Chaining)
```python
import pandas as pd

df = (
    pd.read_parquet("sales.parquet", dtype_backend="pyarrow")
    .query("amount > 0")
    .assign(
        month=lambda x: x["date"].dt.to_period("M"),
        net=lambda x: x["amount"] * (1 - x["discount"]),
    )
    .groupby(["month", "region"], as_index=False)
    .agg(total_net=("net", "sum"), orders=("id", "count"))
)
```

---

## 3. Exploratory Data Analysis (EDA) & Statistical Checks

1. **Inspeksi Awal**: Skema/tipe data, rasio missing value (`null_count()`), kardinalitas kolom kategorikal, duplikasi primary key.
2. **Distribusi & Outlier**:
   - Gunakan **Median + IQR** untuk distribusi miring (skewed), **Mean + SD** hanya untuk distribusi mendekati normal.
   - Cek **Correlation Matrix** (Pearson untuk linier, Spearman untuk monotonik non-linier) dan **Cross-tabulation** (`pd.crosstab`) untuk variabel kategorikal.
3. **Data Leakage Prevention**: Selalu lakukan `train_test_split` (atau time-based split untuk time-series) **sebelum** menghitung parameter imputasi/scaling (`StandardScaler`, target encoding).

---

## 4. Data Visualization & Dashboards

| Kebutuhan | Tool Utama | Aturan Praktis |
|-----------|------------|----------------|
| **Publikasi Statis / Custom** | `Matplotlib` + `Seaborn` | Gunakan OO API (`fig, ax = plt.subplots()`), jangan stateful `plt.plot()` |
| **Eksplorasi Interaktif** | `Plotly Express` / `Altair` | Cocok untuk hover detail, zoom time-series, dan embed di web |
| **Data Apps / Internal Dashboard** | `Streamlit` / `Plotly Dash` | Gunakan `@st.cache_data` untuk query/DataFrame dan `@st.cache_resource` untuk koneksi DB/ML model |

```python
import matplotlib.pyplot as plt
import seaborn as sns

fig, ax = plt.subplots(figsize=(8, 5), dpi=150)
sns.regplot(data=df, x="spend", y="revenue", ax=ax)
ax.set(title="Revenue vs Ad Spend", xlabel="Spend (USD)", ylabel="Revenue (USD)")
fig.tight_layout()
fig.savefig("revenue_vs_spend.png")
plt.close(fig)
```

---

## 5. Big Data & Data Pipelines

- **Single-node out-of-core (10 GB – 500 GB)**: Gunakan **DuckDB** atau **Polars Lazy (`sink_parquet`)** sebelum melompat ke cluster terdistribusi.
- **Distributed cluster (> 500 GB)**: Gunakan **PySpark** atau **Dask**.
- **Orchestration (Airflow / Dagster / Prefect)**:
  - **Idempotensi Wajib**: Menjalankan ulang task untuk partisi tanggal yang sama (`logical_date`) harus menghasilkan output yang identik tanpa duplikasi baris (gunakan `INSERT OVERWRITE` / `MERGE` / tulis ulang partisi Parquet).
  - Jangan lewatkan DataFrame besar antar-task via XCom; simpan di object storage (S3/GCS) dalam format **Parquet** dan kirimkan URI-nya saja.
