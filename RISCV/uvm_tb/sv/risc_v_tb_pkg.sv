`timescale 1ns/1ps
// risc_v_tb_pkg.sv
// Package wrapper that unifies all verification classes into ONE
// compilation-unit scope. Each class keeps its own source file.
package risc_v_tb_pkg;
    import uvm_pkg::*;

    `include "uvm_macros.svh"
    // Peripheral analysis-channel type (shared, declared once for the package)
    `uvm_analysis_imp_decl(_periph)
    `include "risc_v_seq_item.sv"
    // Peripheral agent types referenced by scoreboard/coverage/env below
    `include "risc_v_periph_seq_item.sv"
    `include "risc_v_periph_driver.sv"
    `include "risc_v_periph_monitor.sv"
    `include "risc_v_periph_agent.sv"
    `include "risc_v_periph_seqs.sv"
    // CPU agents and analysis components
    `include "risc_v_seqs.sv"
    `include "risc_v_driver.sv"
    `include "risc_v_monitor.sv"
    `include "risc_v_scoreboard.sv"
    `include "risc_v_coverage.sv"
    `include "risc_v_agent.sv"
    `include "risc_v_env.sv"
    `include "risc_v_test.sv"
endpackage
