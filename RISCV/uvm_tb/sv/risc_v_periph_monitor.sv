`timescale 1ns/1ps
`ifndef RISC_V_PERIPH_MONITOR_SV
`define RISC_V_PERIPH_MONITOR_SV
`include "uvm_macros.svh"
import uvm_pkg::*;

// Samples the physical peripheral outputs and status registers once per
// clock cycle and broadcasts a risc_v_periph_seq_item to scoreboard &
// coverage. Also derives simple edge hints used by the analysis agents.
class risc_v_periph_monitor extends uvm_monitor;

    `uvm_component_utils(risc_v_periph_monitor)

    virtual risc_v_if vif;

    uvm_analysis_port #(risc_v_periph_seq_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db#(virtual risc_v_if)::get(this, "", "vif", vif))
            `uvm_fatal("PMON", "No virtual interface found for risc_v_periph_monitor")
    endfunction

    task run_phase(uvm_phase phase);
        risc_v_periph_seq_item item;
        bit sck_prev, cs_prev;
        forever begin
            @(posedge vif.clk);
            if (vif.reset) begin
                sck_prev = vif.spi_sck;
                cs_prev  = vif.spi_cs;
                continue;
            end
            item = risc_v_periph_seq_item::type_id::create("item");
            item.tach_on            = 1'bx;
            item.spi_sck            = vif.periph_mon_cb.spi_sck;
            item.spi_mosi           = vif.periph_mon_cb.spi_mosi;
            item.spi_cs             = vif.periph_mon_cb.spi_cs;
            item.pwm_out            = vif.periph_mon_cb.pwm_out;
            item.spi_busy           = vif.periph_mon_cb.spi_busy;
            item.stall              = vif.periph_mon_cb.stall;
            item.fail_safe_active   = vif.periph_mon_cb.fail_safe_active;
            item.spi_rx_out         = vif.periph_mon_cb.spi_rx_out;
            item.spi_done_out       = vif.periph_mon_cb.spi_done_out;
            item.pwm_period_out     = vif.periph_mon_cb.pwm_period_out;
            item.pwm_duty_out       = vif.periph_mon_cb.pwm_duty_out;
            item.rpm_period_out     = vif.periph_mon_cb.rpm_period_out;
            item.rpm_valid_out      = vif.periph_mon_cb.rpm_valid_out;
            item.profile_loaded_out = vif.periph_mon_cb.profile_loaded_out;
            item.profile_active_out = vif.periph_mon_cb.profile_active_out;
            item.wdt_timeout_out    = vif.periph_mon_cb.wdt_timeout_out;

            item.sck_rise = vif.spi_sck && !sck_prev;
            item.sck_fall = !vif.spi_sck && sck_prev;
            item.cs_rise  = vif.spi_cs && !cs_prev;
            item.cs_fall  = !vif.spi_cs && cs_prev;
            sck_prev = vif.spi_sck;
            cs_prev  = vif.spi_cs;
            ap.write(item);
        end
    endtask

endclass

`endif
