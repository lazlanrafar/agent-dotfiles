---
name: cs-and-algorithms
description: >-
  Computer Science and Data Structures & Algorithms skill based on roadmap.sh/computer-science
  and roadmap.sh/datastructures-and-algorithms.
  Enforces asymptotic complexity analysis (Big-O time & space), optimal data structure selection
  (Hash Table, Heap, Deque, Trie, B-Tree, Graph), cache-friendly memory access, and algorithmic patterns.
  Use when optimizing hot paths, choosing data structures, solving algorithmic problems, or reviewing complexity.
---

# Computer Science & Algorithms Skill

Pedoman pemilihan struktur data, analisis kompleksitas, dan algoritma inti berbasis kurikulum `roadmap.sh/computer-science` dan `roadmap.sh/datastructures-and-algorithms`.

---

## 1. Pemilihan Struktur Data (`O(1)` vs `O(log n)` vs `O(n)`)

Selalu pilih struktur data berdasarkan operasi dominan pada jalur kritis (*hot path*):

| Kebutuhan Operasi Dominan | Struktur Data Salah (Sering Terjadi) | Struktur Data Tepat | Kompleksitas |
|---------------------------|--------------------------------------|---------------------|--------------|
| Cek keanggotaan (`x in items`) berulang kali | `list` / `Array` (`O(n)`) | **`set` / `HashSet`** | **`O(1)` rata-rata** |
| Antrean FIFO (`pop` dari depan) | `list.pop(0)` / `Vec::remove(0)` (`O(n)`) | **`deque` / `VecDeque`** | **`O(1)`** |
| Ambil elemen terkecil/terbesar Top-K terus-menerus | `sort()` ulang tiap iterasi (`O(n log n)`) | **`heapq` / `BinaryHeap`** | **`O(log n)` push/pop, `O(n log k)` Top-K** |
| Pencarian range / floor / ceiling terurut | Scan linier (`O(n)`) | **Sorted Array + `bisect` (`O(log n)`) / `BTreeMap`** | **`O(log n)`** |
| Autocomplete / prefix matching string | Filter semua string (`O(N * L)`) | **Trie (Prefix Tree) / Radix Tree** | **`O(L)` panjang prefix** |
| Cache dengan batas kapasitas | Dict tanpa batas (memory leak) | **LRU Cache (Hash Map + Doubly Linked List)** | **`O(1)` get/put** |
| Melacak komponen terhubung dinamis | BFS/DFS berulang kali | **Disjoint Set / Union-Find** | **`O(α(n))` ≈ `O(1)`** |

---

## 2. Pola Algoritma Inti untuk Engineering Produksi

1. **Two Pointers & Sliding Window (`O(n)`)**:
   - Gunakan untuk pencarian subarray/substring kontigu, rate-limiting sliding window, atau deduplikasi array terurut tanpa alokasi memori ekstra (`O(1)` space).
2. **Binary Search on Answer (`O(log(range) * check)`)**:
   - Tidak hanya untuk mencari elemen di array terurut; gunakan saat fungsi predikat bersifat monotonik (`False, False, ..., True, True`), misalnya mencari kapasitas minimum worker atau batas threshold optimal.
3. **Graph & Dependency Resolution**:
   - **Shortest Path**: **BFS** untuk graf tak berbobot (`O(V + E)`), **Dijkstra** (dengan Min-Heap) untuk bobot non-negatif (`O((V + E) log V)`).
   - **DAG & Urutan Eksekusi (Build System, Task Workflow, Migration)**: Gunakan **Topological Sort (Kahn's Algorithm / Indegree atau DFS 3-warna)** sekaligus untuk mendeteksi *cycle* (circular dependency).
4. **Recursion vs Iteration**:
   - Di bahasa tanpa *Tail-Call Optimization* (seperti Python dan sebagian besar target Rust), pohon/graf yang dalam (`depth > 1000`) bisa memicu `RecursionError` / stack overflow. Gunakan **eksplisit stack/queue iteratif** untuk input yang kedalamannya tidak terbatas.

---

## 3. Systems Thinking: Memory Hierarchy & Bit Manipulation

- **Spatial & Temporal Locality**: Array kontigu (`Vec<T>`, NumPy ndarray) jauh lebih cepat di CPU cache L1/L2 dibanding struktur berbasis pointer tersebar (Linked List / pohon objek Python) meskipun Big-O di atas kertas sama.
- **Streaming / Constant-Memory Processing (`O(1)` Space)**:
  - Saat memproses file/stream besar, gunakan iterator/generator satu lintasan (*single-pass*).
  - Untuk statistik streaming: gunakan **Welford's algorithm** untuk rata-rata/variansi online, **Reservoir Sampling** untuk sampel acak ukuran `k`, atau **HyperLogLog / Bloom Filter** untuk kardinalitas dan cek keanggotaan probabilistik hemat memori.
