# ======================================================================
#  UVM Simulation script for MyCapstone RISC-V
#
#  Usage:  vsim -c -do sim/run.tcl  (+ multiple args)
#  or      vlog -sv -f sim/filelist.f  &&  vsim -c ...
#
#  Full flow (ModelSim/Questa):
#     vlib work
#     vlog -sv -f sim/filelist.f
#     vsim -c -novopt work.risc_v_uvm_tb -do "
#         set UVM_TESTNAME risc_v_golden_test;
#         add wave /risc_v_uvm_tb/vif/*;
#         run -all;
#         quit"
# ======================================================================

# Synthesis/compile status: RTL is intended for Intel FPGA (Quartus).
# RTL files are assembled separately in Quartus. This list is for sim only.

# SystemVerilog source (RTL)
../adder.sv
../alu.sv
../alu_control.sv
../control_unit.sv
../cu.sv
../ecc_data_mem.sv
../ecc_decoder.sv
../ecc_encoder.sv
../error_status_reg.sv
../fault_injector.sv
"../imm_ext .sv"
../instr_mem.sv
../mux.sv
../pc.sv
../reg_file.sv
../risc_v.sv
../sys_bus.sv
../peripherals.sv

# === UVM verification environment ===
# All classes are unified in one package (single compilation-unit scope)
sv/risc_v_if.sv
sv/risc_v_tb_pkg.sv
sv/risc_v_uvm_tb.sv