`timescale 1ns/1ps
`ifndef RISC_V_PERIPH_SEQ_ITEM_SV
`define RISC_V_PERIPH_SEQ_ITEM_SV
`include "uvm_macros.svh"
import uvm_pkg::*;

// MISO driving modes (what the SPI slave agent does on the wire)
typedef enum logic [1:0] {
    SPI_IDLE      = 2'b00,   // MISO forced low
    SPI_LOOPBACK  = 2'b01,   // MISO reflects MOSI (RX == TX)
    SPI_ECHO      = 2'b10    // MISO shifts out echo_byte, MSB first
} spi_miso_mode_e;

// Transaction: peripheral stimulus configuration + per-cycle observation
class risc_v_periph_seq_item extends uvm_sequence_item;

    `uvm_object_utils(risc_v_periph_seq_item)

    // ---- Stimulus config fields (consumed by periph driver) ----
    rand bit           tach_on;
    rand bit [15:0]    tach_period;      // full tach period in clock cycles
    rand spi_miso_mode_e miso_mode;
    rand byte          echo_byte;

    // ---- Observed fields (sampled by periph monitor every cycle) ----
    bit        spi_sck;
    bit        spi_mosi;
    bit        spi_cs;
    bit        pwm_out;
    bit        spi_busy;
    bit        stall;
    bit        fail_safe_active;
    bit [7:0]  spi_rx_out;
    bit        spi_done_out;
    bit [15:0] pwm_period_out;
    bit [15:0] pwm_duty_out;
    bit [31:0] rpm_period_out;
    bit        rpm_valid_out;
    bit        profile_loaded_out;
    bit        profile_active_out;
    bit        wdt_timeout_out;

    // ---- Edge hints (derived by monitor) ----
    bit        sck_rise;
    bit        sck_fall;
    bit        cs_rise;
    bit        cs_fall;

    // ---- Constraints ----
    constraint c_tach_default {
        tach_period inside {[4:64]};
    }
    constraint c_mode_default {
        miso_mode dist {SPI_LOOPBACK := 60, SPI_ECHO := 20, SPI_IDLE := 20};
    }

    function new(string name = "risc_v_periph_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("tach=%0b per=%0d mode=%s echo=%02h | sck=%0b mosi=%0b cs=%0b busy=%0b done=%0b rx=%02h | pwm=%0b duty=%0d period=%0d | rpm=%0d valid=%0b | prof_ld=%0b prof_act=%0b | wdt=%0b fs=%0b stall=%0b",
                         tach_on, tach_period, miso_mode.name(), echo_byte,
                         spi_sck, spi_mosi, spi_cs, spi_busy, spi_done_out, spi_rx_out,
                         pwm_out, pwm_duty_out, pwm_period_out,
                         rpm_period_out, rpm_valid_out,
                         profile_loaded_out, profile_active_out,
                         wdt_timeout_out, fail_safe_active, stall);
    endfunction

    function void do_copy(uvm_object rhs);
        risc_v_periph_seq_item r;
        super.do_copy(rhs);
        if (!$cast(r, rhs)) `uvm_fatal("COPY", "cast failed");
        tach_on            = r.tach_on;
        tach_period        = r.tach_period;
        miso_mode          = r.miso_mode;
        echo_byte          = r.echo_byte;
        spi_sck            = r.spi_sck;
        spi_mosi           = r.spi_mosi;
        spi_cs             = r.spi_cs;
        pwm_out            = r.pwm_out;
        spi_busy           = r.spi_busy;
        stall              = r.stall;
        fail_safe_active   = r.fail_safe_active;
        spi_rx_out         = r.spi_rx_out;
        spi_done_out       = r.spi_done_out;
        pwm_period_out     = r.pwm_period_out;
        pwm_duty_out       = r.pwm_duty_out;
        rpm_period_out     = r.rpm_period_out;
        rpm_valid_out      = r.rpm_valid_out;
        profile_loaded_out = r.profile_loaded_out;
        profile_active_out = r.profile_active_out;
        wdt_timeout_out    = r.wdt_timeout_out;
        sck_rise           = r.sck_rise;
        sck_fall           = r.sck_fall;
        cs_rise            = r.cs_rise;
        cs_fall            = r.cs_fall;
    endfunction

    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        risc_v_periph_seq_item r;
        if (!$cast(r, rhs)) return 0;
        return (super.do_compare(rhs, comparer) &&
                tach_on === r.tach_on &&
                tach_period === r.tach_period &&
                pwm_out === r.pwm_out &&
                spi_busy === r.spi_busy &&
                stall === r.stall &&
                fail_safe_active === r.fail_safe_active &&
                spi_rx_out === r.spi_rx_out &&
                spi_done_out === r.spi_done_out &&
                rpm_valid_out === r.rpm_valid_out &&
                profile_loaded_out === r.profile_loaded_out &&
                wdt_timeout_out === r.wdt_timeout_out);
    endfunction
endclass

`endif
