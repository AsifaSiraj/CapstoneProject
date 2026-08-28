## **RISC-V Processor Design (Verilog)**



### **1. INTRODUCTION TO RISC-V PROCESSOR**

---
This project implements a **RISC-V processor** using **Verilog HDL**. RISC-V is an open-source Reduced Instruction Set Computer (RISC) architecture designed for simplicity and efficiency.

The project demonstrates the core components of a RISC-V processor, including instruction fetch, decode, execution, memory access, and write-back.

It is intended for learning computer architecture, processor design, and Verilog simulation.

---
### **2. PROJECT STRUCTURE**
---
**RISC-V Processor**

RISC-V/

├── adder.v

├── alu.v

├── alu\_control.v

├── clk\_div.v

├── control\_unit.v

├── cu.v

├── data\_mem.v

├── imm\_ext.v

├── inst\_memory.v

├── instr\_mem.v

├── mux.v

├── pc.v

├── reg\_file.v

├── risc\_v.v

└── risc\_v\_tb.v
---
### **3. MODULES**
---
#### **1. adder.v**

This module implements an adder used in the RISC-V processor.

* Performs arithmetic addition operations.
* Commonly used for:

* Program Counter increment
* Address calculations
* Ensures correct arithmetic functionality within the datapath.
---
#### **2. alu.v**

This module implements the Arithmetic Logic Unit (ALU). 
Performs arithmetic and logical operations such as:

* Addition
* Subtraction
* AND, OR, XOR
* Takes two operands and an ALU control signal as inputs.
* Outputs the computed result used by other processor stages.
---
#### **3. alu\_control.v**

This module generates ALU control signals.

* Decodes instruction function fields.
* Determines the exact operation the ALU should perform.
* Acts as an interface between the control unit and the ALU.
---
**4. clk\_div.v**

This module implements a clock divider.
Generates a slower clock from a high-frequency input clock.
Useful for:

* Simulation
* Debugging
* Visual observation of processor operation
---
#### **5. control\_unit.v**

This module implements the main control unit.

* Decodes the instruction opcode.
* Generates control signals for:
* Register write
* Memory access
* ALU operations
* Directs data flow throughout the processor.
---
#### **6. cu.v**

This module acts as a central control logic block.

* Coordinates control signals between different sub-modules.
* Ensures proper instruction execution sequence.
* Helps manage overall processor control flow.
---
#### **7. data\_mem.v**

This module implements data memory.
Used for load and store instructions.
Supports memory read and write operations.
Controlled by signals from the control unit.

---
#### **8. imm\_ext.v**

This module implements the Immediate Extension Unit.

* Extracts immediate fields from instructions.
* Performs sign extension as required.
* Supports different RISC-V instruction formats.
---
#### **9. instr\_mem.v**

These modules implement instruction memory.

* Stores RISC-V instructions.
* Outputs instruction based on Program Counter value.
* Used during the instruction fetch stage.
---
#### **10. mux.v**

This module implements multiplexers used in the data path.
Selects between multiple input signals.
Used for:

* Operand selection
* Write-back selection
* Controlled by control unit signals.
---
#### **11. pc.v**

This module implements the Program Counter (PC).

* Holds the address of the current instruction.
* Updates every clock cycle.
* Supports sequential instruction execution.
---
#### **12. reg\_file.v**

This module implements the RISC-V Register File.
Contains 32 general-purpose registers. Supports:
Two read ports
One write port
Register x0 is hardwired to zero.

---
#### **13. risc\_v.v**

This is the top-level module of the RISC-V processor. It integrates all processor components:

* PC
* Instruction Memory
* Register File
* ALU
* Control Unit
* Data Memory
* Implements the full instruction execution cycle:

* Fetch
* Decode
* Execute
* Memory
* Write-back
---
#### **14. risc\_v\_tb.v**

This module is the testbench for the RISC-V processor

* Generates clock and test signals.
* Verifies processor functionality.
* Used for simulation and debugging.
---

## 4. **GETTING STARTED**
---
git clone https://github.com/your-username/RISC-V.git
cd RISC-V

---
## 5. **USAGE**
---
1\. Open **ModelSim / Quartus Prime / Vivado**.
2\. Create a new project and add all Verilog files.
3\. Compile the design.
4\. Run the testbench (*risc\_v\_tb.v*).
5\. Observe waveforms and outputs.


## 7. **Contributing**
---
If you would like to contribute to this project, please fork the repository and submit a pull request.
***
---
---
---


