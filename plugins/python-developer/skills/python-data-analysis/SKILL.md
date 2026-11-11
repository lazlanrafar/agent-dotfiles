---
name: python-data-analysis
description: >-
  Python Data Analysis, Visualization, and Data Engineering skill based on roadmap.sh/python-data-analysis.
  Enforces vectorized NumPy, Polars/Pandas 2.x (PyArrow), rigorous EDA (IQR, correlation, leakage prevention),
  publication-grade Matplotlib/Seaborn/Plotly visualizations, Streamlit/Dash apps, and idempotent DuckDB/PySpark/Airflow pipelines.
  Use whenever analyzing datasets, cleaning data, building charts/dashboards, or designing data pipelines in Python.
---

# Python Data Analysis Skill

Pedoman analisis data, visualisasi, dan data pipeline berbasis kurikulum [roadmap.sh/python-data-analysis](https://roadmap.sh/python-data-analysis).

> **Referensi lengkap**: [`../python-developer/references/data-analysis-and-pipelines.md`](../python-developer/references/data-analysis-and-pipelines.md)

---

## 1. Aturan Emas Data Manipulation (NumPy, Polars, Pandas)

1. **Vectorization Over Loops**: Haram menggunakan `for` loop, `.iterrows()`, atau `.apply(axis=1)` untuk operasi kolom numerik/string. Gunakan ekspresi ter-vektorisasi.
2. **Polars / DuckDB First untuk Beban Kerja Modern**:
   - Gunakan **Polars** (`scan_parquet` + lazy API) atau **DuckDB** untuk pemrosesan cepat, hemat memori, dan multi-core.
   - Jika menggunakan **Pandas 2.x**, aktifkan `dtype_backend="pyarrow"` dan gunakan method chaining (`.assign()`, `.query()`, `.pipe()`) daripada mutasi `df["col"] = ...` berantai yang memicu `SettingWithCopyWarning`.
3. **Storage Format**: Gunakan **Parquet** (atau Arrow IPC) untuk penyimpanan antartahap. Hindari CSV untuk dataset > 50 MB karena tidak menyimpan skema tipe data dan lambat di-parse.
4. **Reproducibility**: Selalu kunci generator acak dengan `rng = np.random.default_rng(42)`.

---

## 2. Protokol Exploratory Data Analysis (EDA)

Setiap kali menganalisis dataset baru, jalankan pemeriksaan berurutan ini:
1. **Schema & Integrity Check**: Dimensi `(rows, cols)`, tipe data tiap kolom, duplikasi primary key, dan persentase missing values.
2. **Distribusi & Outlier**:
   - Laporkan **Mean + SD** untuk distribusi simetris, DAN **Median + IQR** (`Q75 - Q25`) untuk distribusi skewed.
   - Deteksi outlier menggunakan batas IQR (`[Q25 - 1.5*IQR, Q75 + 1.5*IQR]`) atau Z-score (`|z| > 3`). Jangan hapus outlier tanpa memeriksa apakah itu data valid atau error pencatatan.
3. **Relasi & Korelasi**:
   - Numerik vs Numerik: korelasi **Pearson** (linier) & **Spearman** (monotonik/rank).
   - Kategorikal vs Kategorikal: **Cross-tabulation** (`crosstab`) + uji Chi-Square jika relevan.
4. **Anti-Data Leakage**: Jika menyiapkan fitur untuk pemodelan, pisahkan train/validation/test **sebelum** menghitung statistik imputasi, scaling, atau encoding. Untuk data berurutan waktu, wajib gunakan **time-based split**.

---

## 3. Data Visualization & Dashboards

- **Matplotlib / Seaborn**: Selalu gunakan Object-Oriented interface (`fig, ax = plt.subplots()`), beri label sumbu beserta satuannya, judul yang menjelaskan temuan utama, dan tutup figure (`plt.close(fig)`) setelah disimpan.
- **Plotly**: Gunakan untuk grafik interaktif (time-series multi-metrik, hover inspeksi anomali).
- **Streamlit / Dash**:
  - Pisahkan fungsi komputasi data murni dari kode rendering UI.
  - Wajib cache pembacaan data dengan `@st.cache_data` dan koneksi DB/model dengan `@st.cache_resource`.

---

## 4. Big Data & Pipeline Engineering

- **Scale Up Sebelum Scale Out**: Satu mesin modern dengan **DuckDB** atau **Polars streaming** mampu memproses puluhan hingga ratusan GB Parquet lebih cepat dan murah dibanding mengangkat cluster Spark kecil.
- **PySpark / Dask**: Gunakan ketika data melampaui kapasitas disk/RAM single-node. Hindari Python UDF di PySpark; gunakan built-in `pyspark.sql.functions` atau Pandas/Arrow Vectorized UDF.
- **Airflow / Dagster**:
  - Setiap task wajib **idempotent** dan **atomic** (safe untuk di-retry kapan saja).
  - Jangan pernah menyimpan payload data di database metadata orchestrator (XCom); kirimkan path/URI penyimpanan objek (S3/GCS/lokal).
