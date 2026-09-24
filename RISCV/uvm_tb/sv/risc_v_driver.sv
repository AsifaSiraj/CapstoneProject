`timescale 1ns/1ps
`ifndef RISC_V_DRIVER_SV
`define RISC_V_DRIVER_SV
`include "uvm_macros.svh"
import uvm_pkg::*;

class risc_v_driver extends uvm_driver #(risc_v_seq_item);

    `uvm_component_utils(risc_v_driver)

    virtual risc_v_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual risc_v_if)::get(this, "", "vif", vif))
            `uvm_fatal("DRV", "No virtual interface found for risc_v_driver")
    endfunction

    task run_phase(uvm_phase phase);
        risc_v_seq_item req;
        // Drive idle values while reset is asserted
        vif.fault_inject_en  <= 1'b0;
        vif.fault_bit_pos    <= '0;
        vif.fault_inject_en2 <= 1'b0;
        vif.fault_bit_pos2   <= '0;
        wait (vif.reset === 1'b1);
        wait (vif.reset === 1'b0);
        forever begin
            seq_item_port.get_next_item(req);
            drive_transfer(req);
            seq_item_port.item_done();
        end
    endtask

    task drive_transfer(risc_v_seq_item req);
        @(posedge vif.clk);
        vif.drv_cb.fault_inject_en  <= req.fault_inject_en;
        vif.drv_cb.fault_bit_pos    <= req.fault_bit_pos;
        vif.drv_cb.fault_inject_en2 <= req.fault_inject_en2;
        vif.drv_cb.fault_bit_pos2   <= req.fault_bit_pos2;
    endtask

endclass

`endif


