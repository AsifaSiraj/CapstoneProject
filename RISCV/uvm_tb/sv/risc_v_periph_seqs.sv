`timescale 1ns/1ps
`ifndef RISC_V_PERIPH_SEQS_SV
`define RISC_V_PERIPH_SEQS_SV
`include "uvm_macros.svh"
import uvm_pkg::*;

// ------------------------------------------------------------------
// 1) Default world: rotor running at period/2, SPI slave loops back
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
// 2) Stop the rotor (watchdog / fail-safe test) - PWM fail-safe trigger
// ------------------------------------------------------------------
class risc_v_tach_off_seq extends uvm_sequence #(risc_v_periph_seq_item);
    `uvm_object_utils(risc_v_tach_off_seq)

    function new(string name = "risc_v_tach_off_seq");
        super.new(name);
    endfunction

    task body();
        risc_v_periph_seq_item req;
        req = risc_v_periph_seq_item::type_id::create("req");
        start_item(req);
        req.tach_on     = 1'b0;
        req.tach_period = 16'd40;
        req.miso_mode   = SPI_LOOPBACK;
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

// ------------------------------------------------------------------
// 4) Varying rotor speed for RPM period coverage
// ------------------------------------------------------------------
class risc_v_tach_sweep_seq extends uvm_sequence #(risc_v_periph_seq_item);
    `uvm_object_utils(risc_v_tach_sweep_seq)

    bit [15:0] periods[] = '{16'd20, 16'd40, 16'd60};

    function new(string name = "risc_v_tach_sweep_seq");
        super.new(name);
    endfunction

    task body();
        risc_v_periph_seq_item req;
        foreach (periods[i]) begin
            req = risc_v_periph_seq_item::type_id::create("req");
            start_item(req);
            req.tach_on     = 1'b1;
            req.tach_period = periods[i];
            req.miso_mode   = SPI_LOOPBACK;
            finish_item(req);
            #1000;                          // let the DUT settle at this speed
        end
    endtask
endclass

// ------------------------------------------------------------------
// 5) Watchdog / fail-safe sequence: let the program arm the WDT while
//    the rotor is turning, then stop the rotor and let it time out
// ------------------------------------------------------------------
class risc_v_watchdog_failsafe_seq extends uvm_sequence #(risc_v_periph_seq_item);
    `uvm_object_utils(risc_v_watchdog_failsafe_seq)

    int cycles_before_stall = 260;      // program reaches FS_CTRL ~cycle 90

    function new(string name = "risc_v_watchdog_failsafe_seq");
        super.new(name);
    endfunction

    task body();
        risc_v_periph_seq_item req;

        // rotor turning, SPI loopback (normal operation)
        req = risc_v_periph_seq_item::type_id::create("req");
        start_item(req);
        req.tach_on     = 1'b1;
        req.tach_period = 16'd40;
        req.miso_mode   = SPI_LOOPBACK;
        finish_item(req);

        // let the program enable the watchdog and enter its halt loop
        #(cycles_before_stall * 10);

        // rotor stalls -> watchdog must time out and drive fail-safe
        req = risc_v_periph_seq_item::type_id::create("req");
        start_item(req);
        req.tach_on     = 1'b0;
        req.tach_period = 16'd40;
        req.miso_mode   = SPI_LOOPBACK;
        finish_item(req);

        // wait for the 256-cycle WDT timeout + margin, observe fail-safe
        #6000;
    endtask
endclass

`endif
