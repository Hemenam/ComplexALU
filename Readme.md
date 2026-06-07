# Complex-Number ALU with Pipelined Execution

A multi-cycle arithmetic logic unit for complex numbers, implemented in Verilog and deployed on the Altera DE2 FPGA board.

The project enforces a strict hardware constraint: **only one real adder, one real multiplier, and one real divider are allowed in the entire design**. Despite this, the ALU supports five complex-number operations through time-multiplexed scheduling via a finite state machine.

---

## Features

| Operation                  | Code  | Cycles | Hardware used per cycle       |
| -------------------------- | :---: | :----: | ----------------------------- |
| Complex addition           | `000` |   2    | adder × 1                     |
| Complex subtraction        | `001` |   2    | adder × 1                     |
| Complex multiplication     | `010` |   5    | mul ≤1, adder ≤1 (overlapped) |
| Complex division           | `011` |   9    | mul ≤1, adder ≤1, divider ≤1  |
| Magnitude squared `\|z\|²` | `100` |   3    | mul ≤1, adder ≤1              |

- 8-bit signed real and imaginary components (16-bit complex word)
- 32-word data memory with 2 read ports + 1 write port
- 32-instruction program memory (18-bit instructions)
- Pipelined IF/MEM/EX with stall-based hazard handling
- LED output mapping for live status display on the DE2 board

---

## Project versions

### v1 — Basic ALU

The original implementation supporting **add, subtract, and multiply** with the single-multiplier / single-adder constraint. The instruction word is 17 bits with a 2-bit op field.

### v2 — Extended ALU

Adds two new operations while preserving the resource constraint:

- **Complex division** using `(a+bi)/(c+di) = ((ac+bd) + (bc−ad)i) / (c²+d²)`, scheduled across 9 cycles. Requires adding a single shared divider unit.
- **Magnitude squared** computed as `|z|² = Re² + Im²` in just 3 cycles. Reuses existing mul and adder — zero new hardware.

The op field is widened to 3 bits and the instruction word grows to 18 bits. The top-level pipeline also exposes LED outputs for board deployment.

---

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ inst_fetch  │────▶│   memory    │────▶│     alu     │
│  (IF/PC)    │     │ (operands)  │     │ (multi-cyc) │
└─────────────┘     └─────────────┘     └─────────────┘
       ▲                                       │
       │ stall                                 │ alu_done
       └───────────── pipeline ────────────────┘
                  (handshake controller)
```

### Multi-cycle ALU scheduling

The ALU runs a 20-state FSM. Each state routes the shared units' inputs via combinational muxes; results propagate through intermediate registers (`t_ac`, `t_bd`, `t_ad`, `t_bc`, `t_cc`, `t_dd`, `num_re`, `num_im`, `denom`).

Example — complex multiply schedule:

| Cycle |  Multiplier   |   Adder   | Stored at next edge               |
| :---: | :-----------: | :-------: | :-------------------------------- |
|  M1   | `Re(a)·Re(b)` |   idle    | `t_ac ← ac`                       |
|  M2   | `Im(a)·Im(b)` |   idle    | `t_bd ← bd`                       |
|  M3   | `Re(a)·Im(b)` | `ac − bd` | `t_ad ← ad`, `Re(result) ← ac−bd` |
|  M4   | `Im(a)·Re(b)` |   idle    | `t_bc ← bc`                       |
|  M5   |     idle      | `ad + bc` | `Im(result) ← ad+bc`, done        |

Notice the M3 row — both shared units are active in the same cycle but on independent operations, which is what saves a cycle over the naive 6-cycle schedule.

### Pipeline handshake

The IF and MEM stages run combinationally while the multi-cycle EX stage processes one instruction over multiple cycles. A `ready_to_issue` signal lets the next instruction enter EX on the same edge that the previous instruction's writeback fires, achieving a 1-cycle issue gap between back-to-back instructions.

```verilog
wire ready_to_issue = !busy || alu_done;
wire stall          = busy && !alu_done;
wire wb_en          = alu_done;
```

---

## Repository structure

```
.
├── README.md
├── Makefile
│
├── macros.v             — word-width and complex-number macros
├── addsub.v             — single real adder/subtractor (8-bit)
├── mul.v                — single real multiplier (8-bit)
├── divider.v            — single real divider (v2 only)
├── alu.v                — multi-cycle complex ALU with FSM
├── inst_fetch.v         — instruction memory + PC + stall handling
├── memory.v             — data memory (2-read, 1-write)
├── pipeline.v           — top-level pipeline controller
│
├── addsub_TB.v          — unit testbench for addsub
├── mul_TB.v             — unit testbench for mul
├── alu_TB.v             — full ALU testbench (all 5 ops in v2)
├── pipeline_TB.v        — end-to-end pipeline testbench
│
├── data/
│   ├── inst_mem.txt     — program (instructions in binary)
│   └── initial_mem.txt  — initial data memory contents
│
└── pipeline_pins.qsf    — Quartus pin assignments for DE2 (v2 only)
```

---

## Quick start

### Prerequisites

- **Simulation**: [Icarus Verilog](http://iverilog.icarus.com/) or ModelSim
- **Synthesis & FPGA deployment**: Quartus II 13.0+ (Web Edition is free)
- **Hardware**: Altera DE2 board (Cyclone II EP2C35F672C6)

### Simulate with Icarus Verilog

```bash
make pipeline      # compile and run the full pipeline testbench
make alu           # ALU unit tests (all 5 ops)
make mul           # multiplier unit tests
make addsub        # adder unit tests
```

Expected output from `make pipeline`:

```
#120  WB  mem[2] <= (4, 6)     (op=000, a=(3,4), b=(1,2))    ← add
#200  WB  mem[3] <= (2, 2)     (op=001, a=(3,4), b=(1,2))    ← sub
#340  WB  mem[4] <= (-5, 10)   (op=010, a=(3,4), b=(1,2))    ← mul
#560  WB  mem[5] <= (5, 5)     (op=011, a=(10,10), b=(2,0))  ← div
#660  WB  mem[8] <= (25, 0)    (op=100, a=(3,4), b=(3,4))    ← magsq
```

### Simulate in ModelSim

1. Set up the Quartus project with all `.v` files except the testbenches.
2. `Assignments → Settings → EDA Tool Settings → Simulation → NativeLink settings → Test Benches…` and register each testbench:

   | Name          | Top module    | File            |
   | ------------- | ------------- | --------------- |
   | `addsub_TB`   | `addsub_TB`   | `addsub_TB.v`   |
   | `mul_TB`      | `mul_TB`      | `mul_TB.v`      |
   | `alu_TB`      | `alu_TB`      | `alu_TB.v`      |
   | `pipeline_TB` | `pipeline_TB` | `pipeline_TB.v` |

3. Select the testbench from the _Compile test bench_ dropdown.
4. `Tools → Run Simulation Tool → RTL Simulation`.
5. In the ModelSim transcript: `run -all`.

> **Note**: Place `data/inst_mem.txt` and `data/initial_mem.txt` inside `simulation/modelsim/data/` for ModelSim to find them.

---

## FPGA deployment (v2 only)

### Pin mapping

The pipeline exposes its state on the DE2 board's LEDs:

| Signal       | LEDs              | Meaning                           |
| ------------ | ----------------- | --------------------------------- |
| `LEDR[7:0]`  | red, bottom row   | Real part of last ALU result      |
| `LEDR[15:8]` | red, middle row   | Imaginary part of last ALU result |
| `LEDR[16]`   | red               | ALU busy                          |
| `LEDR[17]`   | red               | Done pulse                        |
| `LEDG[4:0]`  | green             | Program counter                   |
| `LEDG[7:5]`  | green             | Current op code                   |
| `LEDG[8]`    | green             | Heartbeat (rstN status)           |
| `KEY[0]`     | push button       | Reset (active-low)                |
| `CLOCK_50`   | 50 MHz oscillator | System clock                      |

### Deployment steps

1. Open Quartus and create a project with `pipeline` as the top-level entity.
2. Add all source files (excluding testbenches).
3. `Assignments → Import Assignments… → pipeline_pins.qsf`.
4. Make sure `data/inst_mem.txt` and `data/initial_mem.txt` are in the project root. The `initial $readmemb` blocks in `inst_fetch.v` and `memory.v` will bake the program into the bitstream.
5. Compile: `Ctrl + L`.
6. Flash via `Tools → Programmer` with USB Blaster connected.

### Data file format note

Quartus's `$readmemb` parser is stricter than ModelSim's. Data files must contain **only binary digits**, one per word, with no underscores or comments:

```
000000100000000001    ← good (Quartus-compatible)
000_00010_00000_00001 ← bad (Quartus rejects underscores)
```

### Clock note

At 50 MHz the full program completes in roughly 1 µs — invisible to the human eye. The LEDs settle on the final instruction's result and stay there. To watch instructions execute one at a time, insert a clock divider (~25-bit counter on `CLOCK_50` to get ~1.5 Hz).

---

## Verified test results

### ALU operations

```
add:    (3+4i) + (1+2i)   = (4, 6)     ✓
sub:    (3+4i) − (1+2i)   = (2, 2)     ✓
mul:    (3+4i) × (1+2i)   = (-5, 10)   ✓
div:    (10+10i) ÷ (2+0i) = (5, 5)     ✓
div:    (3+4i) ÷ (1+2i)   = (2, 0)     ✓ (integer truncation of 2.2 − 0.4i)
magsq:  |3+4i|²           = 25         ✓
magsq:  |6+8i|²           = 100        ✓
```

### Pipeline end-to-end

Final memory state after running the test program:

```
mem[2] = (4, 6)      ← add
mem[3] = (2, 2)      ← sub
mem[4] = (-5, 10)    ← mul
mem[5] = (5, 5)      ← div
mem[8] = (25, 0)     ← magsq
```

The pipeline correctly handles data dependencies — `mem[5]` uses values written by the two preceding instructions, and the stall + writeback logic resolves the hazard transparently.

---

## Known limitations

- **8-bit overflow**: products and squared magnitudes can overflow the 8-bit signed range. For example, `12 × 12 = 144` wraps to `-112`, and `|10+10i|² = 200` exceeds the range.
- **Integer division truncation**: division uses Verilog's integer `/`, so fractional results lose precision. `(3+4i)/(1+2i)` mathematically equals `2.2 − 0.4i` but computes as `(2, 0)`. For higher precision, use fixed-point arithmetic with explicit pre-shifting.
- **PC increment**: the program counter uses `pc + 1`, which infers an implicit adder outside the shared `addsub` unit. A strict reading of the constraint would route PC increment through the shared adder as well.
- **No ALU-internal pipelining**: the ALU processes one instruction at a time. Throughput could be improved with internal pipelining, but this would conflict with the single-unit constraint.

---

## Design takeaways

- The single biggest cycle-count win is **overlapping the adder with the multiplier** in M3 and M5 (mul) and in D3, D5, D7 (div). Without that, each operation would take 1-2 more cycles.
- **State reuse**: the four cross-products `ac, bd, ad, bc` are computed identically for mul and div — only the combining signs differ. The temp registers `t_ac, t_bd, t_ad, t_bc` are also reused across all three ops (mul, div, magsq).
- **Magsq is essentially free**: zero new hardware, 3 cycles, pure reuse of existing units. A good demonstration of how careful FSM design lets you add functionality without growing area.
- **`initial $readmemb` for synthesis**: works in Quartus to bake ROM contents into the bitstream, but the data file syntax is stricter than for simulation tools. Maintaining two file formats is annoying — alternatively, use a Quartus `.mif` file.

---

## License

Educational project. No license claim — feel free to use for learning or coursework.

## Acknowledgments

Designed for the Digital Systems Design laboratory course, Sharif University of Technology. Adapted from the original 3-operation reference design provided with the course materials, with the lab's hardware-constraint requirement enforced rigorously.
