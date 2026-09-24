# run.tcl — compile + simulate one UVM test
#
# Usage (QuestaSim 2024.x):
#   vsim -c -do "set UVM_TESTNAME risc_v_golden_test; do sim/run.tcl"
#
# Usage (ModelSim Intel FPGA / ModelSim SE):
#   vsim -c -do "set UVM_TESTNAME risc_v_golden_test; do sim/run.tcl" -L mtiUvm
#   (ModelSim may require compiling UVM sources first, see README section 5.)

if {[info exists UVM_TESTNAME]} {
    puts "Running UVM test: $UVM_TESTNAME"
} else {
    set UVM_TESTNAME risc_v_golden_test
    puts "No UVM_TESTNAME set, defaulting to $UVM_TESTNAME"
}

# ---- Compile (clean workspace) ----
if {[file isdirectory work]} { vdel -lib work -all }
vlib work
vmap work work

# Questa ships the UVM library built-in (mtiUvm).
# For ModelSim without built-in UVM, add:
#   set UVM_DIR <path-to>/uvm-1.2/src
#   vlog +incdir+$UVM_DIR $UVM_DIR/uvm_pkg.sv
vlog -sv +incdir+sv -f sim/filelist.f

# ---- Simulate ----
vsim -c work.risc_v_uvm_tb \
     +UVM_TESTNAME=$UVM_TESTNAME \
     +UVM_VERBOSITY=UVM_MEDIUM \
     -do "run -all"

exit