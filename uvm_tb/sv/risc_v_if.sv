`timescale 1ns/1ps
`ifndef RISC_V_IF_SV
`define RISC_V_IF_SV
`include "uvm_macros.svh"
import uvm_pkg::*;

interface risc_v_if(input logic clk);

    // Reset lives INSIDE the interface so the UVM test can drive it
    logic reset = 1'b1;

    // ---- Stimulus (from CPU agent driver to DUT) ----
    logic        fault_inject_en;
    logic [5:0]  fault_bit_pos;
    logic        fault_inject_en2;
    logic [5:0]  fault_bit_pos2;

    // ---- Stimulus: physical peripheral inputs (from periph agent driver) ----
    logic        tach_in = 1'b0;
    logic        spi_miso = 1'b0;

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

    // ---- Physical peripheral outputs ----
    logic        spi_sck;
    logic        spi_mosi;
    logic        spi_cs;
    logic        pwm_out;
    logic        spi_busy;
    logic        stall;
    logic        fail_safe_active;

    // ---- Peripheral observability (read-back of status registers) ----
    logic [7:0]  spi_rx_out;
    logic        spi_done_out;
    logic [15:0] pwm_period_out;
    logic [15:0] pwm_duty_out;
    logic [31:0] rpm_period_out;
    logic        rpm_valid_out;
    logic        profile_loaded_out;
    logic        profile_active_out;
    logic        wdt_timeout_out;

    // ---- Clocking block for CPU driver ----
    clocking drv_cb @(posedge clk);
        default input #1 output #1;
        output fault_inject_en;
        output fault_bit_pos;
        output fault_inject_en2;
        output fault_bit_pos2;
    endclocking

    // ---- Clocking block for periph driver ----
    clocking periph_drv_cb @(posedge clk);
        default input #1 output #1;
        // drive async/deasserted values in the clocking domain is not used;
        // tach_in and spi_miso are driven with real-time assignments instead.
    endclocking

    // ---- Clocking block for CPU monitor ----
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
        input spi_sck;
        input spi_mosi;
        input spi_cs;
        input pwm_out;
        input spi_busy;
        input stall;
        input fail_safe_active;
        input spi_rx_out;
        input spi_done_out;
        input pwm_period_out;
        input pwm_duty_out;
        input rpm_period_out;
        input rpm_valid_out;
        input profile_loaded_out;
        input profile_active_out;
        input wdt_timeout_out;
    endclocking

    // ---- Clocking block for periph monitor ----
    clocking periph_mon_cb @(posedge clk);
        default input #1 output #1;
        input spi_sck;
        input spi_mosi;
        input spi_cs;
        input pwm_out;
        input spi_busy;
        input stall;
        input fail_safe_active;
        input spi_rx_out;
        input spi_done_out;
        input pwm_period_out;
        input pwm_duty_out;
        input rpm_period_out;
        input rpm_valid_out;
        input profile_loaded_out;
        input profile_active_out;
        input wdt_timeout_out;
    endclocking

    // ---- Modports ----
    modport driver  (clocking drv_cb, input clk, reset);
    modport monitor (clocking mon_cb, input clk, reset);
    modport periph_driver  (input clk, reset, output tach_in, spi_miso);
    modport periph_monitor (clocking periph_mon_cb, input clk, reset,
                            output tach_in, spi_miso);
    modport dut_mp  (input  clk, reset,
                     fault_inject_en, fault_bit_pos,
                     fault_inject_en2, fault_bit_pos2,
                     tach_in, spi_miso,
                     output result_src, memwrite, alu_src, regwrite, pc_src,
                     imm_src, pc, inst, alu_result, wd, rd,
                     single_err_corrected, double_err_detected,
                     error_addr, peripheral_reg_out,
                     spi_sck, spi_mosi, spi_cs, pwm_out, spi_busy, stall,
                     fail_safe_active, spi_rx_out, spi_done_out,
                     pwm_period_out, pwm_duty_out, rpm_period_out,
                     rpm_valid_out, profile_loaded_out, profile_active_out,
                     wdt_timeout_out);

    // ===================================================================
    //  Assertions
    // ===================================================================

    // ---- CPU core: PC always word-aligned ----
    property pc_increments_by_4_or_jumps;
        @(posedge clk) disable iff(reset)
        (pc[1:0] == 2'b00);
    endproperty
    assert property(pc_increments_by_4_or_jumps)
        else $error("PC not word-aligned at time %0t", $time);

    // ---- Reset: no back-to-back assertion ----
    property no_consecutive_reset;
        @(posedge clk) disable iff(reset)
        $rose(reset) |=> !reset;
    endproperty
    assert property(no_consecutive_reset)
        else $warning("Reset asserted twice in a row");

    // ---- SPI: chip-select low implies a busy transfer in progress ----
    property spi_cs_low_means_busy;
        @(posedge clk) disable iff(reset)
        (spi_cs == 1'b0) |-> (spi_busy == 1'b1);
    endproperty
    assert property(spi_cs_low_means_busy)
        else $error("SPI CS asserted (low) while SPI not busy at %0t", $time);

    // ---- SPI: serial clock must be quiet while CS is high (idle) ----
    property spi_sck_idle_when_cs_high;
        @(posedge clk) disable iff(reset)
        (spi_cs == 1'b1) |-> (spi_sck == 1'b0);
    endproperty
    assert property(spi_sck_idle_when_cs_high)
        else $error("SPI SCK toggling while chip-select is de-asserted at %0t", $time);

    // ---- SPI: exactly 8 MISO sampling acts not strictly verified here;
    //       MISO must not be sampled when CS is high (no stray clocking).
    // ---- Stall request only makes sense while SPI is busy ----
    property stall_implies_spi_busy;
        @(posedge clk) disable iff(reset)
        (stall) |-> (spi_busy);
    endproperty
    assert property(stall_implies_spi_busy)
        else $error("Stall asserted while SPI is not busy at %0t", $time);

    // ---- Fail-safe: active fail-safe forces PWM output low ----
    property fail_safe_forces_pwm_low;
        @(posedge clk) disable iff(reset)
        (fail_safe_active) |-> (pwm_out == 1'b0);
    endproperty
    assert property(fail_safe_forces_pwm_low)
        else $error("PWM is high while fail-safe is active at %0t", $time);

    // ---- Watchdog timeout is a fail-safe trigger (latched together) ----
    property wdt_timeout_implies_fail_safe;
        @(posedge clk) disable iff(reset)
        $rose(wdt_timeout_out) |=> fail_safe_active;
    endproperty
    assert property(wdt_timeout_implies_fail_safe)
        else $error("Watchdog timeout without fail-safe latch at %0t", $time);

    // ---- RPM: once valid, stays valid until reset (sticky) ----
    property rpm_valid_sticky;
        @(posedge clk) disable iff(reset)
        $rose(rpm_valid_out) |=> (rpm_valid_out [*2]);
    endproperty
    assert property(rpm_valid_sticky)
        else $error("RPM valid flag de-asserted after becoming valid at %0t", $time);

    // ---- SPI RX: received byte must be 8 bits wide and stable after done ----
    property spi_rx_stable_after_done;
        logic [7:0] rx;
        @(posedge clk) disable iff(reset)
        ($rose(spi_done_out), rx = spi_rx_out) |=> ##1 (spi_rx_out == rx);
    endproperty
    assert property(spi_rx_stable_after_done)
        else $error("SPI RX register changed after transfer done at %0t", $time);

endinterface

`endif
