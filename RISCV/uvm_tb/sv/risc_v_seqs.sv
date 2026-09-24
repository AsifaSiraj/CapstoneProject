`timescale 1ns/1ps
`ifndef RISC_V_SEQS_SV
`define RISC_V_SEQS_SV
`include "uvm_macros.svh"
import uvm_pkg::*;

// ------------------------------------------------------------------
// 1) Base sequence: drives fault injection disabled (golden run)
// ------------------------------------------------------------------
class risc_v_golden_seq extends uvm_sequence #(risc_v_seq_item);
    `uvm_object_utils(risc_v_golden_seq)

    int num_cycles = 20;

    function new(string name = "risc_v_golden_seq");
        super.new(name);
    endfunction

    task body();
        risc_v_seq_item req;
        repeat (num_cycles) begin
            req = risc_v_seq_item::type_id::create("req");
            start_item(req);
            req.fault_inject_en  = 1'b0;
            req.fault_bit_pos    = '0;
            req.fault_inject_en2 = 1'b0;
            req.fault_bit_pos2   = '0;
            finish_item(req);
        end
    endtask
endclass

// ------------------------------------------------------------------
// 2) Single-bit fault injection (SEC expected: 1 correction, no detect)
// ------------------------------------------------------------------
class risc_v_single_bit_fault_seq extends uvm_sequence #(risc_v_seq_item);
    `uvm_object_utils(risc_v_single_bit_fault_seq)

    int unsigned cycles_before_fault = 5;
    logic [5:0]  fault_bit_pos;

    function new(string name = "risc_v_single_bit_fault_seq");
        super.new(name);
    endfunction

    task body();
        risc_v_seq_item req;
        if (fault_bit_pos > 6'd38) fault_bit_pos = 6'd10;   // guard
        repeat (cycles_before_fault) begin
            req = risc_v_seq_item::type_id::create("req");
            start_item(req);
            req.fault_inject_en  = 1'b0;
            req.fault_inject_en2 = 1'b0;
            finish_item(req);
        end
        req = risc_v_seq_item::type_id::create("req");
        start_item(req);
        req.fault_inject_en  = 1'b1;
        req.fault_bit_pos    = fault_bit_pos;
        req.fault_inject_en2 = 1'b0;
        finish_item(req);
        repeat (cycles_before_fault) begin
            req = risc_v_seq_item::type_id::create("req");
            start_item(req);
            req.fault_inject_en  = 1'b0;
            req.fault_inject_en2 = 1'b0;
            finish_item(req);
        end
    endtask
endclass

// ------------------------------------------------------------------
// 3) Double-bit fault injection (DED expected: detect, no correction)
// ------------------------------------------------------------------
class risc_v_double_bit_fault_seq extends uvm_sequence #(risc_v_seq_item);
    `uvm_object_utils(risc_v_double_bit_fault_seq)

    int unsigned cycles_before_fault = 5;
    logic [5:0]  fault_bit_pos;
    logic [5:0]  fault_bit_pos2;

    function new(string name = "risc_v_double_bit_fault_seq");
        super.new(name);
    endfunction

    task body();
        risc_v_seq_item req;
        repeat (cycles_before_fault) begin
            req = risc_v_seq_item::type_id::create("req");
            start_item(req);
            req.fault_inject_en  = 1'b0;
            req.fault_inject_en2 = 1'b0;
            finish_item(req);
        end
        req = risc_v_seq_item::type_id::create("req");
        start_item(req);
        req.fault_inject_en  = 1'b1;
        req.fault_bit_pos    = fault_bit_pos;
        req.fault_inject_en2 = 1'b1;
        req.fault_bit_pos2   = fault_bit_pos2;
        finish_item(req);
        repeat (cycles_before_fault) begin
            req = risc_v_seq_item::type_id::create("req");
            start_item(req);
            req.fault_inject_en  = 1'b0;
            req.fault_inject_en2 = 1'b0;
            finish_item(req);
        end
    endtask
endclass

// ------------------------------------------------------------------
// 4) Random stress: mostly clean, some single and double faults
// ------------------------------------------------------------------
class risc_v_random_stress_seq extends uvm_sequence #(risc_v_seq_item);
    `uvm_object_utils(risc_v_random_stress_seq)

    int unsigned num_cycles = 40;

    function new(string name = "risc_v_random_stress_seq");
        super.new(name);
    endfunction

    task body();
        risc_v_seq_item req;
        int roll;
        repeat (num_cycles) begin
            req = risc_v_seq_item::type_id::create("req");
            start_item(req);
            roll = $urandom_range(99);
            req.fault_bit_pos  = $urandom_range(38);
            req.fault_bit_pos2 = $urandom_range(38);
            if (roll < 70) begin
                req.fault_inject_en  = 1'b0;
                req.fault_inject_en2 = 1'b0;
            end else if (roll < 90) begin
                req.fault_inject_en  = 1'b1;
                req.fault_inject_en2 = 1'b0;
            end else begin
                req.fault_inject_en  = 1'b1;
                req.fault_inject_en2 = 1'b1;
            end
            finish_item(req);
        end
    endtask
endclass

// ------------------------------------------------------------------
// 5) Directed MMIO sequence (peripheral register read/write)
// ------------------------------------------------------------------
class risc_v_mmio_seq extends uvm_sequence #(risc_v_seq_item);
    `uvm_object_utils(risc_v_mmio_seq)

    int num_cycles = 16;

    function new(string name = "risc_v_mmio_seq");
        super.new(name);
    endfunction

    task body();
        risc_v_seq_item req;
        repeat (num_cycles) begin
            req = risc_v_seq_item::type_id::create("req");
            start_item(req);
            req.fault_inject_en  = 1'b0;
            req.fault_inject_en2 = 1'b0;
            finish_item(req);
        end
    endtask
endclass

`endif
