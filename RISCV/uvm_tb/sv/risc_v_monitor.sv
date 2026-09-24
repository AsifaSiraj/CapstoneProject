`timescale 1ns/1ps
`ifndef RISC_V_MONITOR_SV
`define RISC_V_MONITOR_SV
`include "uvm_macros.svh"
import uvm_pkg::*;

class risc_v_monitor extends uvm_monitor;

    `uvm_component_utils(risc_v_monitor)

    virtual risc_v_if vif;

    uvm_analysis_port #(risc_v_seq_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db#(virtual risc_v_if)::get(this, "", "vif", vif))
            `uvm_fatal("MON", "No virtual interface found for risc_v_monitor")
    endfunction

    task run_phase(uvm_phase phase);
        risc_v_seq_item item;
        forever begin
            @(posedge vif.clk);
            if (vif.reset) continue;
            item = risc_v_seq_item::type_id::create("item");
            collect_data(item);
            ap.write(item);
        end
    endtask

    function void collect_data(risc_v_seq_item item);
        item.result_src        = vif.mon_cb.result_src;
        item.memwrite          = vif.mon_cb.memwrite;
        item.alu_src           = vif.mon_cb.alu_src;
        item.regwrite          = vif.mon_cb.regwrite;
        item.pc_src            = vif.mon_cb.pc_src;
        item.imm_src           = vif.mon_cb.imm_src;
        item.pc                = vif.mon_cb.pc;
        item.inst              = vif.mon_cb.inst;
        item.opcode_ref        = vif.mon_cb.inst[6:0];
        item.alu_result        = vif.mon_cb.alu_result;
        item.wd                = vif.mon_cb.wd;
        item.rd                = vif.mon_cb.rd;
        item.single_err_corrected = vif.mon_cb.single_err_corrected;
        item.double_err_detected  = vif.mon_cb.double_err_detected;
        item.error_addr        = vif.mon_cb.error_addr;
        item.peripheral_reg_out = vif.mon_cb.peripheral_reg_out;
        // carry stimulus values for cross-checking in scoreboard/coverage
        item.fault_inject_en   = vif.fault_inject_en;
        item.fault_bit_pos     = vif.fault_bit_pos;
        item.fault_inject_en2  = vif.fault_inject_en2;
        item.fault_bit_pos2    = vif.fault_bit_pos2;
    endfunction

endclass

`endif


