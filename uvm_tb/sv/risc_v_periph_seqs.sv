`timescale 1ns/1ps
`ifndef RISC_V_PERIPH_SEQS_SV
`define RISC_V_PERIPH_SEQS_SV
`include "uvm_macros.svh"
import uvm_pkg::*;

// ------------------------------------------------------------------
// 1) Default world: SPI slave loops back
// ------------------------------------------------------------------
class risc_v_periph_default_seq extends uvm_sequence #(risc_v_periph_seq_item);
    `uvm_object_utils(risc_v_periph_default_seq)

    bit [15:0] tach_period = 16'd40;

    function new(string name = "risc_v_periph_default_seq");
        super.new(name);
    endfunction

    task body();
        risc_v_periph_seq_item req;
        req = risc_v_periph_seq_item::type_id::create("req");
        start_item(req);
        req.tach_on     = 1'b1;
        req.tach_period = tach_period;
        req.miso_mode   = SPI_LOOPBACK;
        req.echo_byte   = 8'hAA;
        finish_item(req);
    endtask
endclass

// ------------------------------------------------------------------
// 3) SPI slave echoes a known byte (checks RX against echo_payload)
// ------------------------------------------------------------------
class risc_v_spi_echo_seq extends uvm_sequence #(risc_v_periph_seq_item);
    `uvm_object_utils(risc_v_spi_echo_seq)

    byte echo_byte = 8'h5A;

    function new(string name = "risc_v_spi_echo_seq");
        super.new(name);
    endfunction

    task body();
        risc_v_periph_seq_item req;
        req = risc_v_periph_seq_item::type_id::create("req");
        start_item(req);
        req.tach_on     = 1'b1;
        req.tach_period = 16'd40;
        req.miso_mode   = SPI_ECHO;
        req.echo_byte   = echo_byte;
        finish_item(req);
    endtask
endclass

`endif
