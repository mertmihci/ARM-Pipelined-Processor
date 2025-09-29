# 32-bit Pipelined ARM Processor with Hazard Unit  

## Project Overview  
This project was developed as part of the **EE446 Computer Architecture Laboratory** at METU.  
I designed and implemented a **32-bit pipelined ARM processor** in **Verilog HDL**, featuring a **hazard detection and resolution unit**.  

The processor executes instructions in a **5-stage pipeline** (Fetch, Decode, Execute, Memory, Writeback), with **forwarding, stalling, and flushing mechanisms** for hazard handling. The design was synthesized and tested on the **Nexys A7 FPGA** board.  

## Features  
- **Pipelined Datapath** with 5 stages (IF, ID, EX, MEM, WB)  
- **Controller** with support for conditional execution (EQ, NE, AL)  
- **Hazard Unit** handling:  
  - Data hazards → forwarding + minimal stalling (1 cycle for memory ops)  
  - Control hazards → pipeline flushing + PC forwarding  
- **Instruction Support** (subset of ARM ISA):  
  - Data processing: `ADD`, `SUB`, `AND`, `ORR`, `MOV`, `CMP`  
  - Memory access: `STR`, `LDR`  
  - Branching: `B`, `BL`, `BX`  
- **Register shifted immediate operations** supported via shifter  
- **Top-level integration** with debug outputs (PC + register values)  
- **Supplied testbench** verifying correctness of the implementation  

## Tools & Technologies  
- **HDL**: Verilog  
- **Testbench**: Cocotb testbench. to run in cmd:
   ```bash
   make
- **Hardware**: Xilinx Nexys A7 FPGA  
- **Software**: Vivado 

## Pipeline Design  
- **Fetch (IF)**: Instruction memory read  
- **Decode (ID)**: Instruction decoding, register file read  
- **Execute (EX)**: ALU/shifter operations, branch decision  
- **Memory (MEM)**: Data memory access  
- **Writeback (WB)**: Register file write  

Hazards are resolved using a dedicated **hazard unit**:  
- Forwarding paths from EX/MEM/WB stages  
- Stalling for load-use hazards  
- Flushing for branch mispredictions and jumps  

## How to Run  
1. Clone this repository  
2. Open the project in Vivado 
3. Run the provided testbench to validate the design  
4. Synthesize and upload the processor to the **Nexys A7 FPGA**  
5. Use the FPGA switches and seven-segment display for debugging (PC + register values)  


