// risc_v_tb_pkg.sv
// Package wrapper that unifies all verification classes into ONE
// compilation-unit scope. Each class keeps its own source file.
package risc_v_tb_pkg;
    import uvm_pkg::*;

    `include "uvm_macros.svh"
    `include "risc_v_seq_item.sv"
    `include "risc_v_seqs.sv"
    `include "risc_v_driver.sv"
    `include "risc_v_monitor.sv"
    `include "risc_v_scoreboard.sv"
    `include "risc_v_coverage.sv"
    `include "risc_v_agent.sv"
    `include "risc_v_env.sv"
    `include "risc_v_test.sv"
endpackage