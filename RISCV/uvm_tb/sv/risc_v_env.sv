`timescale 1ns/1ps
`ifndef RISC_V_ENV_SV
`define RISC_V_ENV_SV
`include "uvm_macros.svh"
import uvm_pkg::*;

class risc_v_env extends uvm_env;

    `uvm_component_utils(risc_v_env)

    risc_v_agent       agt;
    risc_v_periph_agent p_agt;
    risc_v_scoreboard  scb;
    risc_v_coverage    cov;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt  = risc_v_agent::type_id::create("agt", this);
        p_agt = risc_v_periph_agent::type_id::create("p_agt", this);
        scb  = risc_v_scoreboard::type_id::create("scb", this);
        cov  = risc_v_coverage::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // CPU monitor -> scoreboard & coverage
        agt.mon.ap.connect(scb.sb_export);
        agt.mon.ap.connect(cov.analysis_export);
        // Periph monitor -> scoreboard & coverage (second channel)
        p_agt.mon.ap.connect(scb.periph_export);
        p_agt.mon.ap.connect(cov.periph_export);
    endfunction

endclass

`endif


