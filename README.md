
#  RISC-V Pipelined Processor with 2-Level Cache Controller

## 📌 Overview

This project implements a **5-stage pipelined RISC-V processor** fully integrated with a **2-level cache hierarchy** to demonstrate real-world improvements in instruction throughput and memory latency reduction.

The entire design is written in **Verilog HDL**, synthesized, and tested using **Xilinx Vivado**.

---

## ⚙️ Pipeline Architecture

- **Pipeline Stages**
  - **IF**: Instruction Fetch
  - **ID**: Instruction Decode
  - **EX**: Execute
  - **MEM**: Memory Access
  - **WB**: Write Back

- **Pipeline Registers** isolate each stage for instruction-level parallelism.

- **Hazard Detection Unit** automatically handles data hazards with stalls or forwarding.

- **Control Unit** generates control signals to coordinate pipeline flow.

---

## 🗂️ Cache Controller

- **2-Level Cache Hierarchy**
  - **L1 Cache**: Direct-mapped, fast single-cycle access for instructions and data.
  - **L2 Cache**: 4-way set-associative with **LRU (Least Recently Used)** replacement policy, providing better conflict miss handling than direct-mapped alone.

- **Write Strategy**
  - **Write-back**: Modified blocks write back to lower memory only on eviction.
  - **Write-no-allocate**: On a write miss, data is written directly to the next level or main memory without allocating a new cache block — reduces unnecessary fills for poor-write-locality patterns.

This hierarchy balances **fast access (L1)** and **higher capacity (L2)** while minimizing main memory traffic.

---

## ⚡ Performance Analysis

### ⏱️ Clock Design

| Component | Period | Frequency |
|-----------------|---------|--------------|
| **Processor Clock** | 20 ns | 50 MHz |
| **Cache Controller Clock** | 6 ns | ~167 MHz |

- The processor clock is chosen to fit pipeline logic, hazard detection, and register access.
- The cache controller runs faster to complete tag comparisons and set indexing well within each processor cycle.

---

### 🧩 Cache & Memory Latencies (Cache Clock Cycles)

| Memory Level | Latency (cache clock cycles) | Latency (ns) | Approx. CPU clock cycles |
|----------------|-------------------------------|-----------------|-----------------------------|
| **L1 Cache** | 1 cycle | 6 ns | ~0.3 CPU cycles |
| **L2 Cache** | 3 cycles | 18 ns | ~0.9 CPU cycles |
| **Main Memory** | 10 cycles | 60 ns | ~3 CPU cycles |


---

## 📈 CPI & Speedup Comparison

### 🔍 Scenario

- **Main Memory Latency**: 10 cycles of cache controller clock  
  → At 6 ns per cache cycle → 60 ns total.
  → In CPU clock units (20 ns): `60 ns ÷ 20 ns = 3 CPU cycles`.

- **Hierarchy:**
  - **L1**: 1 CPU cycle
  - **L2**: 3 CPU cycles
  - **Main Memory**: ~3 CPU cycles

- **Typical Load/Store Fraction:** ~30% of instructions.

---

### ⚡ CPI Estimates

| | Without Cache | With L1/L2 Cache |
|----------------|-----------------|---------------------|
| **Pipeline Ideal CPI** | ~1.0 | ~1.0 |
| **Practical CPI** | ~1.6 | ~1.03 |

**How it’s calculated:**

- **No Cache:**  
  Every load/store takes 3 CPU cycles (direct main memory access).  


**Estimates:**
- L1 Hit Rate: ~95%
- L2 covers ~50% of remaining misses → only ~2.5% reach main memory
- Effective average memory latency:
