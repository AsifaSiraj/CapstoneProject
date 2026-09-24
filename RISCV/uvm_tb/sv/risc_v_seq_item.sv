`timescale 1ns/1ps
`ifndef RISC_V_SEQ_ITEM_SV
`define RISC_V_SEQ_ITEM_SV
`include "uvm_macros.svh"
import uvm_pkg::*;

// Transaction: control & observation for one instruction cycle / ECC cycle
class risc_v_seq_item extends uvm_sequence_item;

    `uvm_object_utils(risc_v_seq_item)

    // ---- Stimulus fields (driven) ----
    rand logic        fault_inject_en;
    rand logic [5:0]  fault_bit_pos;
    rand logic        fault_inject_en2;
    rand logic [5:0]  fault_bit_pos2;

    // ---- Observed fields (from DUT) ----
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

    // ---- Prediction fields (filled by scoreboard reference model) ----
    logic [6:0]  opcode_ref;
    logic [31:0] alu_result_ref;
    logic [31:0] rd_exp;
    logic        branch_taken_ref;
    logic        single_err_exp;
    logic        double_err_exp;

    // ---- Constraints ----
    // Default: no fault injection
    constraint c_no_fault_default {
        fault_inject_en  dist {0 := 90, 1 := 10};
        fault_inject_en2 == 0;
    }
    constraint c_fault_pos_valid {
        fault_bit_pos  inside {[0:38]};
        fault_bit_pos2 inside {[0:38]};
    }

    // ---- Useful tasks ----
    function new(string name = "risc_v_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("en0=%0b pos0=%0d en1=%0b pos1=%0d | PC=%h INST=%h ALU=%h | RW=%0b MW=%0b | SE=%0b DE=%0b addr=%h mmio=%h",
            fault_inject_en, fault_bit_pos, fault_inject_en2, fault_bit_pos2,
            pc, inst, alu_result, regwrite, memwrite,
            single_err_corrected, double_err_detected, error_addr, peripheral_reg_out);
    endfunction

    function void do_copy(uvm_object rhs);
        risc_v_seq_item r;
        super.do_copy(rhs);
        if (!$cast(r, rhs)) `uvm_fatal("COPY", "cast failed");
        fault_inject_en   = r.fault_inject_en;
        fault_bit_pos     = r.fault_bit_pos;
        fault_inject_en2  = r.fault_inject_en2;
        fault_bit_pos2    = r.fault_bit_pos2;
        result_src        = r.result_src;
        memwrite          = r.memwrite;
        alu_src           = r.alu_src;
        regwrite          = r.regwrite;
        pc_src            = r.pc_src;
        imm_src           = r.imm_src;
        pc                = r.pc;
        inst              = r.inst;
        alu_result        = r.alu_result;
        wd                = r.wd;
        rd                = r.rd;
        single_err_corrected = r.single_err_corrected;
        double_err_detected  = r.double_err_detected;
        error_addr        = r.error_addr;
        peripheral_reg_out = r.peripheral_reg_out;
    endfunction

    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        risc_v_seq_item r;
        if (!$cast(r, rhs)) return 0;
        return (super.do_compare(rhs, comparer) &&
                fault_inject_en   === r.fault_inject_en &&
                fault_bit_pos     === r.fault_bit_pos &&
                fault_inject_en2  === r.fault_inject_en2 &&
                fault_bit_pos2    === r.fault_bit_pos2 &&
                pc                === r.pc &&
                inst              === r.inst &&
                alu_result        === r.alu_result &&
                wd                === r.wd &&
                rd                === r.rd &&
                single_err_corrected === r.single_err_corrected &&
                double_err_detected  === r.double_err_detected &&
                error_addr        === r.error_addr &&
                peripheral_reg_out   === r.peripheral_reg_out);
    endfunction
endclass

`endif


