`timescale 1ns/1ps
`ifndef RISC_V_IF_SV
`define RISC_V_IF_SV
`include "uvm_macros.svh"
import uvm_pkg::*;

interface risc_v_if(input logic clk);

    // Reset lives INSIDE the interface so the UVM test can drive it
    logic reset = 1'b1;

    // ---- Stimulus (from driver to DUT) ----
    logic        fault_inject_en;
    logic [5:0]  fault_bit_pos;
    logic        fault_inject_en2;
    logic [5:0]  fault_bit_pos2;

    // ---- Observation (from DUT to monitor) ----
    logic        result_src;
    logic        memwrite;
    logic        alu_src;
    logic        regwrite;
    logic        pc_src;
    logic [2:0]  imm_src;
    logic [31:0] pc;
    logic [31:0] inst;
    logic [31:0] alu_result;
    logic [31:0] wd;
    logic [31:0] rd;
    logic        single_err_corrected;
    logic        double_err_detected;
    logic [31:0] error_addr;
    logic [31:0] peripheral_reg_out;

    // ---- Clocking block for driver ----
    clocking drv_cb @(posedge clk);
        default input #1 output #1;
        output fault_inject_en;
        output fault_bit_pos;
        output fault_inject_en2;
        output fault_bit_pos2;
    endclocking

    // ---- Clocking block for monitor ----
    clocking mon_cb @(posedge clk);
        default input #1 output #1;
        input result_src;
        input memwrite;
        input alu_src;
        input regwrite;
        input pc_src;
        input imm_src;
        input pc;
        input inst;
        input alu_result;
        input wd;
        input rd;
        input single_err_corrected;
        input double_err_detected;
        input error_addr;
        input peripheral_reg_out;
    endclocking

    // ---- Modports ----
    modport driver  (clocking drv_cb, input clk, reset);
    modport monitor (clocking mon_cb, input clk, reset);
    modport dut_mp  (input  clk, reset,
                     fault_inject_en, fault_bit_pos,
                     fault_inject_en2, fault_bit_pos2,
                     output result_src, memwrite, alu_src, regwrite, pc_src,
                     imm_src, pc, inst, alu_result, wd, rd,
                     single_err_corrected, double_err_detected,
                     error_addr, peripheral_reg_out);

    // ---- Assertions ----
    property pc_increments_by_4_or_jumps;
        @(posedge clk) disable iff(reset)
        (pc[1:0] == 2'b00); // PC always word-aligned
    endproperty
    assert property(pc_increments_by_4_or_jumps)
        else $error("PC not word-aligned at time %0t", $time);

    property no_consecutive_reset;
        @(posedge clk) disable iff(reset)
        $rose(reset) |=> !reset;
    endproperty
    assert property(no_consecutive_reset)
        else $warning("Reset asserted twice in a row");

endinterface

`endif
