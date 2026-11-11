---
name: cs-algorithms
description: >-
  Computer Science and Data Structures & Algorithms skill based on roadmap.sh/computer-science
  and roadmap.sh/datastructures-and-algorithms.
  Enforces asymptotic complexity analysis (Big-O time & space), optimal data structure selection
  (Hash Table, Heap, Deque, Trie, B-Tree, Graph), cache-friendly memory access, and algorithmic patterns.
  Use when optimizing hot paths, choosing data structures, solving algorithmic problems, or reviewing complexity.
---

# Computer Science & Algorithms Skill

Data structure selection, complexity analysis, and algorithmic engineering guidelines based on `roadmap.sh/computer-science` and `roadmap.sh/datastructures-and-algorithms`.

---

## 1. Data Structure Selection (`O(1)` vs. `O(log n)` vs. `O(n)`)

Select data structures according to the dominant operation on the critical path:

| Dominant Operation | Common Anti-Pattern | Optimal Structure | Complexity |
|--------------------|---------------------|-------------------|------------|
| Repeated membership checks (`x in items`) | `list` / `Array` (`O(n)`) | **`set` / `HashSet`** | **`O(1)` average** |
| FIFO queue (`pop` from front) | `list.pop(0)` / `Vec::remove(0)` (`O(n)`) | **`deque` / `VecDeque`** | **`O(1)`** |
| Repeated Top-K / min / max extraction | Re-sorting on every step (`O(n log n)`) | **`heapq` / `BinaryHeap`** | **`O(log n)` push/pop, `O(n log k)` Top-K** |
| Ordered range / floor / ceiling queries | Linear scan (`O(n)`) | **Sorted Array + `bisect` / `BTreeMap`** | **`O(log n)`** |
| String prefix / autocomplete search | Scanning all strings (`O(N * L)`) | **Trie (Prefix Tree) / Radix Tree** | **`O(L)` prefix length** |
| Bounded in-memory cache | Unbounded dict (memory leak) | **LRU Cache (Hash Map + Doubly Linked List)** | **`O(1)` get/put** |
| Dynamic connected components | Repeated BFS/DFS | **Disjoint Set (Union-Find)** | **`O(α(n))` ≈ `O(1)`** |

---

## 2. Core Algorithmic Patterns for Production Engineering

1. **Two Pointers & Sliding Window (`O(n)`)**:
   - Use for contiguous subarray/substring constraints, sliding-window rate limiters, and in-place sorted array deduplication (`O(1)` auxiliary space).
2. **Binary Search on the Answer (`O(log(range) * check)`)**:
   - Apply whenever a feasibility predicate `can_satisfy(x)` is monotonic (`False, ..., False, True, ..., True`), such as finding minimum worker capacity or optimal batch thresholds.
3. **Graph Traversal & Dependency Resolution**:
   - **Shortest Path**: **BFS** for unweighted graphs (`O(V + E)`), **Dijkstra** (with a Min-Heap) for non-negative edge weights (`O((V + E) log V)`).
   - **DAG Execution Ordering (Build Systems, Task Schedulers, Migrations)**: Use **Topological Sort (Kahn's in-degree algorithm or 3-color DFS)** to compute valid execution order and detect circular dependencies.
4. **Recursion vs. Iteration**:
   - In languages without guaranteed Tail-Call Optimization (Python, most Rust targets), deep trees/graphs (`depth > 1000`) risk stack overflow (`RecursionError`). Use an **explicit iterative stack/queue** whenever input depth is unbounded.

---

## 3. Systems Thinking: Memory Hierarchy & Streaming

- **Spatial & Temporal Cache Locality**: Contiguous arrays (`Vec<T>`, NumPy `ndarray`) vastly outperform pointer-chasing structures (linked lists, boxed node trees) on modern CPU L1/L2 caches even when asymptotic Big-O is identical.
- **Single-Pass Streaming (`O(1)` Space)**:
  - Process large files and network streams lazily via iterators/generators.
  - Use **Welford's algorithm** for online mean/variance, **Reservoir Sampling** for uniform random samples of size $k$, and **HyperLogLog / Bloom Filters** for memory-bounded cardinality and membership checks.
