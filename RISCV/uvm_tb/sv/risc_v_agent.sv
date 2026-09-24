`timescale 1ns/1ps
`ifndef RISC_V_AGENT_SV
`define RISC_V_AGENT_SV
`include "uvm_macros.svh"
import uvm_pkg::*;

class risc_v_agent extends uvm_agent;

    `uvm_component_utils(risc_v_agent)

    risc_v_driver  drv;
    risc_v_monitor mon;
    uvm_sequencer #(risc_v_seq_item) sqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv = risc_v_driver::type_id::create("drv", this);
        mon = risc_v_monitor::type_id::create("mon", this);
        sqr = uvm_sequencer#(risc_v_seq_item)::type_id::create("sqr", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction

endclass

`endif


