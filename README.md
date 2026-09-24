# MyCapstone

## RISC-V Single-Cycle Processor SoC with SEC-DED ECC Memory and Memory-Mapped Peripherals

A synthesizable SystemVerilog System-on-Chip built around a single-cycle **RV32I**
RISC-V core, extended with:

- **SEC-DED ECC data memory** (extended Hamming code, 32-bit data -> 39-bit
  codeword): corrects every single-bit error, detects every double-bit error.
- **Dual-channel fault injector** for fault-tolerance validation / fault injection
  testing (FIT).
- **MMIO peripheral subsystem** at `0x8000_0000+`: SPI master, PWM generator,
  RPM/tachometer measurement, 8-slot profile memory, and a **watchdog-driven
  fail-safe** that forces PWM off on a double-bit ECC error or watchdog timeout.
- A complete **UVM (IEEE 1800.2 / IEEE 1800-2017) verification environment**:
  two agents, a cycle-exact software reference-model scoreboard, functional +
  cross + PC-reachability coverage, and protocol assertions.

**Result:** all 7 UVM tests pass with **zero UVM_ERROR / UVM_FATAL** and
**1,396 scoreboard checks, 0 errors** (QuestaSim 2024.1, UVM 1.1d built-in).

---

## Project Overview

The design is a single-cycle processor: FETCH -> DECODE -> EXECUTE -> MEMORY ->
WRITEBACK all complete in one clock cycle. An instruction ROM (`instr_mem.sv`)
holds a small bare-metal firmware program that exercises every subsystem:

| Region | Purpose |
|--------|---------|
| `0x00` | `lui x5, 0x80000` — MMIO base in x5 |
| `0x04–0x0C` | TRACE write/read round-trip (MMIO path) |
| `0x10–0x24` | ECC RAM store/load window (**fault-injection target**) |
| `0x28–0x3C` | PWM setup (period=8, duty=3, enable) |
| `0x40–0x44` | RPM enable |
| `0x48–0x68` | SPI: TX `0xAA`, START, poll DONE, read RX |
| `0x6C–0xB0` | Profile payload `{1…8}` + `PROFILE_CTRL.LOAD` |
| `0xB4–0xC8` | Poll PROFILE_STAT, poll RPM_STAT, read RPM_PERIOD |
| `0xCC–0xD0` | Arm watchdog (`FS_CTRL.WDT_EN = 1`) |
| `0xD4` | Read FS_STAT |
| `0xD8` | `beq x0,x0,0` — infinite halt loop |

The `sys_bus` decodes `addr[31]`: addresses `0x0000_0000–0x7FFF_FFFF` go to the
ECC RAM, `0x8000_0000–0xFFFF_FFFF` go to the peripherals.

---

## Directory Structure

```
MyCapstone/
├── README.md                      <- this file
├── *.sv                           <- RTL (SystemVerilog, Intel-FPGA synthesizable)
│   ├── risc_v.sv                  <- SoC top level
│   ├── pc.sv / adder.sv / mux.sv  <- datapath primitives
│   ├── instr_mem.sv               <- instruction ROM + firmware
│   ├── reg_file.sv / imm_ext .sv / alu.sv
│   ├── control_unit.sv / alu_control.sv / cu.sv
│   ├── sys_bus.sv                 <- address decode + RAM/MMIO mux
│   ├── ecc_encoder.sv / ecc_decoder.sv / ecc_data_mem.sv
│   ├── fault_injector.sv / error_status_reg.sv
│   └── peripherals.sv             <- SPI / PWM / RPM / profile / watchdog
│   ├── risc_v_tb.sv               <- legacy directed (non-UVM) SoC testbench
│   └── ecc_data_mem_tb.sv         <- legacy directed ECC memory unit testbench
├── docs/
│   ├── MyCapstone_Technical_Documentation.docx  <- full engineering doc + report
│   └── MyCapstone_Project_Presentation.pptx
├── uvm_tb/
│   ├── README.md                  <- detailed UVM environment documentation
│   ├── sv/                        <- 11 UVM classes + interface + top
│   │   ├── risc_v_if.sv           <- interface, clocking blocks, assertions
│   │   ├── risc_v_tb_pkg.sv       <- package unifying all classes
│   │   ├── risc_v_uvm_tb.sv       <- top: clock gen, DUT hookup, run_test
│   │   ├── risc_v_seq_item.sv / risc_v_seqs.sv
│   │   ├── risc_v_periph_seq_item.sv / risc_v_periph_seqs.sv
│   │   ├── risc_v_driver.sv / risc_v_monitor.sv
│   │   ├── risc_v_periph_driver.sv / risc_v_periph_monitor.sv
│   │   ├── risc_v_agent.sv / risc_v_periph_agent.sv
│   │   ├── risc_v_env.sv
│   │   ├── risc_v_scoreboard.sv   <- reference model + checks
│   │   ├── risc_v_coverage.sv     <- functional covergroups
│   │   └── risc_v_test.sv         <- 7 test classes
│   ├── sim/
│   │   ├── filelist.f             <- compile file list (RTL + UVM TB)
│   │   ├── run.tcl                <- compile + run one test (Questa/ModelSim)
│   │   └── run_tests.bat          <- compile once + run all 7 tests (Windows)
│   ├── waves/                     <- optional VCD waveform dump

```

---

## Required Tools / Environment

| Tool | Version (verified) | Notes |
|------|--------------------|-------|
| **QuestaSim** | 2024.1 | Primary; ships UVM 1.1d built-in (`mtiUvm`) |
| **ModelSim** | Intel FPGA SE 18.1+ / ModelSim SE | Also ships `mtiUvm`; otherwise compile UVM sources first (see below) |
| **OS** | Windows (batch script provided) | The same commands work from any Questa/ModelSim command prompt |

SystemVerilog (IEEE 1800-2017) support is required. No UVM source tree is
needed for QuestaSim — `import uvm_pkg` resolves against the built-in
`mtiUvm` library. For a ModelSim without built-in UVM:

```bash
vlog +incdir+$UVM_SRC $UVM_SRC/uvm_pkg.sv
# then add:  -L mtiUvm   to the vsim command
```

---

## How to Compile and Run the Simulation

Run all commands from the **project root** (`E:\ICS_CHIP\MyCapstone`).

### Option A — UVM testbench (recommended)

The `filelist.f` compiles all 18 RTL modules plus the UVM interface, package,
and top:

```bash
# Manual compile + run a single test (identical to the .bat):
cd "E:/ICS_CHIP/MyCapstone/uvm_tb" 
vlib work
vlog -sv +incdir+sv -f sim/filelist.f
vsim work.risc_v_uvm_tb +UVM_TESTNAME=risc_v_golden_test +UVM_VERBOSITY=UVM_MEDIUM -do "view wave; add wave -r sim:/risc_v_uvm_tb/*; run -all"
```

Or let the provided Tcl script do the compile-and-run for you (it cleans the
`work` library first):

```bash
cd "E:/ICS_CHIP/MyCapstone/uvm_tb" 
set UVM_TESTNAME risc_v_golden_test
do sim/run.tcl
```

The test name is selected with `+UVM_TESTNAME=...` — pick any of:

```
risc_v_golden_test      risc_v_single_bit_test   risc_v_double_bit_test
risc_v_mmio_test        risc_v_stress_test       risc_v_periph_test
risc_v_failsafe_test
```

### Option B — Legacy directed testbenches (non-UVM)

The plain, self-checking testbenches need only the RTL files:

```bash
# ECC memory unit test
vlib work
vlog -sv risc_v.sv pc.sv adder.sv mux.sv instr_mem.sv reg_file.sv "imm_ext .sv" \
        alu.sv control_unit.sv alu_control.sv cu.sv sys_bus.sv ecc_encoder.sv \
        ecc_decoder.sv ecc_data_mem.sv fault_injector.sv error_status_reg.sv \
        peripherals.sv ecc_data_mem_tb.sv
vsim -c work.ecc_data_mem_tb -do "run -all"

# Full SoC directed testbench
vlib work
vlog -sv risc_v.sv pc.sv adder.sv mux.sv instr_mem.sv reg_file.sv "imm_ext .sv" \
        alu.sv control_unit.sv alu_control.sv cu.sv sys_bus.sv ecc_encoder.sv \
        ecc_decoder.sv ecc_data_mem.sv fault_injector.sv error_status_reg.sv \
        peripherals.sv risc_v_tb.sv
vsim -c work.risc_v_tb -do "run -all"
```

> Note: `imm_ext .sv` has a space in its filename, so quote it exactly as shown.

---

## How to Run the Tests

### UVM regression (all 7 tests)

```bash
uvm_tb\sim\run_tests.bat
```

This cleans and compiles the design once, then runs each test to completion,
writing a transcript to `uvm_tb\sim\<test>.log` and printing `[PASS]`/`[FAIL]`
per test. A test passes when its log contains `*** TEST PASSED ***`.

### Individual UVM test

```bash
vsim -c -do "set UVM_TESTNAME risc_v_double_bit_test; do sim/run.tcl"
```

### What each test verifies

| Test | Verifies |
|------|----------|
| `risc_v_golden_test` | Nominal run, no faults: ALU results, loads, stores, branches, PC alignment (40 cycles) |
| `risc_v_single_bit_test` | One injected bit fault (0..38) => `single_err_corrected` latches, data intact |
| `risc_v_double_bit_test` | Two distinct injected faults => `double_err_detected` latches (uncorrectable) |
| `risc_v_mmio_test` | `0x8000_0000` TRACE `sw`/`lw` round-trip via the bus |
| `risc_v_stress_test` | Randomized fault positions/channels, 40 cycles — broad stimulus & coverage |
| `risc_v_periph_test` | Full SoC program (300 cycles): SPI `0xAA` loopback, PWM, RPM, profile load, WDT armed |
| `risc_v_failsafe_test` | Same program (800 cycles); rotor stops after WDT armed => 256-cycle timeout => FAIL_SAFE forces PWM off |

### Legacy tests

```bash
vsim -c work.ecc_data_mem_tb -do "run -all; quit -f"
vsim -c work.risc_v_tb        -do "run -all; quit -f"
```

### Expected transcript output

```
UVM_INFO ... [TEST] *** TEST PASSED ***     (all checks clean)
UVM_INFO ... [COV] Instr coverage     :  ...
UVM_INFO ... [COV] PC reachability    :  ...
--- UVM Report Summary ---
UVM_ERROR :    0
UVM_FATAL :    0
```

---

## How to Reproduce the Reported Results

The reported pass/fail results are fully reproducible on any machine with
QuestaSim 2024.x (or ModelSim with UVM):

1. Install QuestaSim 2024.x and put `vsim`, `vlog`, `vlib` on `PATH` (or set
   the `QUESTA` environment variable to the tool's `win64` folder, e.g.
   `C:\questasim64_2024.1\win64`).
2. From the project root, run:

   ```bash
   uvm_tb\sim\run_tests.bat
   ```

3. Confirm every line reads `[PASS]` and every `sim\*.log` contains
   `*** TEST PASSED ***`.

The reference results captured for this project (QuestaSim 2024.1, UVM 1.1d
built-in):

| Test | Status | Scoreboard | Key coverage / counters |
|------|--------|------------|-------------------------|
| `risc_v_golden_test` | **PASSED** | 42 chk, 0 err | instr 30.4 %, PC 93.3 %, 29 MMIO accesses |
| `risc_v_single_bit_test` | **PASSED** | 13 chk, 0 err | fault at bit 32; 3 single-bit corrections; instr 35.9 % |
| `risc_v_double_bit_test` | **PASSED** | 13 chk, 0 err | faults at bits 1, 23; 3 double-bit detections; instr 37.0 % |
| `risc_v_mmio_test` | **PASSED** | 22 chk, 0 err | 9 MMIO accesses; PC 93.3 % |
| `risc_v_stress_test` | **PASSED** | 42 chk, 0 err | 35 corrections / 20 detections; instr 65.5 %, PC 93.3 % |
| `risc_v_periph_test` | **PASSED** | 302 chk, 0 err | SPI 247, RPM 278, PWM runs 36, Profile 224 events |
| `risc_v_failsafe_test` | **PASSED** | 962 chk, 0 err | RPM 938, fail-safe active 482 cycles |
| **Total** | **7 / 7 PASSED** | **1,396 chk, 0 err** | **0 UVM_ERROR / 0 UVM_FATAL** |

Simulation artifacts you can cross-check against these numbers:

| Artifact | Location |
|----------|----------|
| Per-test transcripts | `uvm_tb/sim/<test>.log` (fresh run) |
| Previously captured transcripts | `uvm_tb/sim_*.log`, `uvm_tb/sim_golden.log`, `uvm_tb/transcript` |
| Waveform dump (optional) | `uvm_tb/waves/tb_dump.vcd` — enable `+define+DUMP_WAVES` in `filelist.f`/`run.tcl` |
| Compiled library | `work/` (generated) |

### Simulation notes/caveats

- **Instruction coverage is program-bounded.** Because `instr_mem.sv` runs one
  fixed firmware program, the opcode/funct3 bins can only open for the opcodes
  the program executes (`lui`, `addi`, `sw`, `lw`, `and`, `beq`, halt). A value
  below 100 % is a quality signal, not a failure. Extend the program in
  `instr_mem.sv` to open more bins.
- Sticky ECC/fail-safe flags are **checked end-of-run** by the scoreboard (the
  `error_status_reg` is a latch), so per-cycle checks are avoided by design.
- The `uvm_tb/sim/*.log` files from a local run without a licence may only
  contain `** Fatal: Unable to obtain a license.**` — delete them (or just
  re-run `run_tests.bat`) to regenerate.

---
