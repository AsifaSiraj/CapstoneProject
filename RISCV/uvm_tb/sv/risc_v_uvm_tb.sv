`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
import risc_v_tb_pkg::*;

module risc_v_uvm_tb;

    logic clk = 0;

    // Interface instance
    risc_v_if vif (.clk(clk));

    // DUT instantiation
    risc_v DUT (
        .clk                   (clk),
        .reset                 (vif.reset),
        .fault_inject_en       (vif.fault_inject_en),
        .fault_bit_pos         (vif.fault_bit_pos),
        .fault_inject_en2      (vif.fault_inject_en2),
        .fault_bit_pos2        (vif.fault_bit_pos2),
        .result_src            (vif.result_src),
        .memwrite              (vif.memwrite),
        .alu_src               (vif.alu_src),
        .regwrite              (vif.regwrite),
        .pc_src                (vif.pc_src),
        .imm_src               (vif.imm_src),
        .pc                    (vif.pc),
        .inst                  (vif.inst),
        .alu_result            (vif.alu_result),
        .wd                    (vif.wd),
        .rd                    (vif.rd),
        .single_err_corrected  (vif.single_err_corrected),
        .double_err_detected   (vif.double_err_detected),
        .error_addr            (vif.error_addr),
        .peripheral_reg_out    (vif.peripheral_reg_out),
        .tach_in               (vif.tach_in),
        .spi_miso              (vif.spi_miso),
        .spi_sck               (vif.spi_sck),
        .spi_mosi              (vif.spi_mosi),
        .spi_cs                (vif.spi_cs),
        .pwm_out               (vif.pwm_out),
        .spi_busy              (vif.spi_busy),
        .stall                 (vif.stall),
        .fail_safe_active      (vif.fail_safe_active),
        .spi_rx_out            (vif.spi_rx_out),
        .spi_done_out          (vif.spi_done_out),
        .pwm_period_out        (vif.pwm_period_out),
        .pwm_duty_out          (vif.pwm_duty_out),
        .rpm_period_out        (vif.rpm_period_out),
        .rpm_valid_out         (vif.rpm_valid_out),
        .profile_loaded_out    (vif.profile_loaded_out),
        .profile_active_out    (vif.profile_active_out),
        .wdt_timeout_out       (vif.wdt_timeout_out)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Initial assertions NOT part of UVM config (kept simple)
    initial begin
        // Wildcard so every component can retrieve the virtual interface
        uvm_config_db#(virtual risc_v_if)::set(null, "*", "vif", vif);
        run_test();
    end

    // Global timeout watchdog
    initial begin
        #50000;
        `uvm_error("TB", "Global simulation timeout reached")
        $finish;
    end

    // Wave dump is optional (keep simulation fast by default).
    // Enable with: +define+DUMP_WAVES and run in GUI / with -wl vcd
    `ifdef DUMP_WAVES
    initial begin
        $dumpfile("waves/tb_dump.vcd");
        $dumpvars(0, risc_v_uvm_tb);
    end
    `endif

endmodule
