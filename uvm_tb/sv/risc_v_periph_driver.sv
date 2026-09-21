`timescale 1ns/1ps
`ifndef RISC_V_PERIPH_DRIVER_SV
`define RISC_V_PERIPH_DRIVER_SV
`include "uvm_macros.svh"
import uvm_pkg::*;

// Drives the physical peripheral inputs (tach_in, spi_miso).
//
// The CPU runs its own program from instruction memory; this driver only
// emulates the external world: a rotating rotor (tachometer pulses) and an
// SPI slave. The mode is set by sequences via risc_v_periph_seq_item.
class risc_v_periph_driver extends uvm_driver #(risc_v_periph_seq_item);

    `uvm_component_utils(risc_v_periph_driver)

    virtual risc_v_if vif;

    // current stimulus configuration (persists between requests)
    bit             tach_on;
    bit [15:0]      tach_period;
    spi_miso_mode_e miso_mode;
    byte            echo_byte;

    int  tach_cnt;
    int  echo_idx;
    logic sck_d, cs_d;      // previous-cycle SPI samples for edge detection

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual risc_v_if)::get(this, "", "vif", vif))
            `uvm_fatal("PDRV", "No virtual interface found for risc_v_periph_driver")
    endfunction

    task run_phase(uvm_phase phase);
        risc_v_periph_seq_item req;

        tach_on     = 1'b0;
        tach_period = 16'd40;
        miso_mode   = SPI_LOOPBACK;
        echo_byte   = 8'hAA;
        echo_idx    = 7;

        vif.tach_in  = 1'b0;
        vif.spi_miso = 1'b0;

        // persistent background behaviour (independent of sequence timing)
        fork
            drive_world();
        join_none

        forever begin
            seq_item_port.get_next_item(req);
            tach_on     = req.tach_on;
            tach_period = (req.tach_period < 16'd2) ? 16'd2 : req.tach_period;
            miso_mode   = req.miso_mode;
            echo_byte   = req.echo_byte;
            if (!tach_on) vif.tach_in = 1'b0;
            seq_item_port.item_done();
        end
    endtask

    // ---- single posedge process: tach generator + SPI slave ----
    // Reads use pre-NBA values so sck_d/cs_d are the *previous* cycle's
    // samples: falling edges of cs/sck are detected against current values.
    task drive_world();
        int half;
        forever begin
            @(posedge vif.clk);
            sck_d = vif.spi_sck;
            cs_d  = vif.spi_cs;

            // ---- tachometer: high/low for tach_period/2 cycles ----
            if (tach_on && tach_period >= 16'd2) begin
                half = tach_period / 2;
                if (tach_cnt >= half - 1) begin
                    vif.tach_in = ~vif.tach_in;
                    tach_cnt    = 0;
                end
                else
                    tach_cnt++;
            end
            else if (!tach_on) begin
                vif.tach_in = 1'b0;
            end

            // ---- SPI slave model ----
            case (miso_mode)
                SPI_LOOPBACK: begin
                    // MISO mirrors MOSI at the master's sampling (rising) edge
                    vif.spi_miso = vif.spi_mosi;
                end
                SPI_ECHO: begin
                    if (cs_d && !vif.spi_cs) begin          // CS fell: first bit
                        echo_idx = 7;
                        vif.spi_miso = echo_byte[7];
                    end
                    else if (sck_d && !vif.spi_sck) begin   // SCK fell: next bit
                        if (echo_idx > 0) echo_idx--;
                        vif.spi_miso = echo_byte[echo_idx];
                    end
                    // otherwise hold current MISO drive value
                end
                default: begin
                    vif.spi_miso = 1'b0;
                end
            endcase
        end
    endtask

endclass

`endif
