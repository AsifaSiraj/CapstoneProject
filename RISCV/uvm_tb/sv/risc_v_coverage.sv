`timescale 1ns/1ps
`ifndef RISC_V_COVERAGE_SV
`define RISC_V_COVERAGE_SV
`include "uvm_macros.svh"
import uvm_pkg::*;

class risc_v_coverage extends uvm_subscriber #(risc_v_seq_item);

    `uvm_component_utils(risc_v_coverage)

    // Second analysis channel for peripheral observations
    uvm_analysis_imp_periph #(risc_v_periph_seq_item, risc_v_coverage) periph_export;

    // Metric counters
    int num_instr = 0;
    int num_single_fault = 0;
    int num_double_fault = 0;
    int num_mmio_access = 0;

    // ---------------------------------------------------------------
    // Functional coverage
    // ---------------------------------------------------------------
    covergroup instr_cg with function sample(risc_v_seq_item item);
        // 1. Instruction opcode coverage
        cp_opcode: coverpoint item.inst[6:0] {
            bins r_type   = {7'b0110011};
            bins i_type   = {7'b0010011};
            bins load     = {7'b0000011};
            bins store    = {7'b0100011};
            bins branch   = {7'b1100011};
            bins jal      = {7'b1101111};
            bins lui      = {7'b0110111};
        }
        // 2. funct3 within R-type (ALU ops)
        cp_alu_fun3: coverpoint item.inst[14:12] iff (item.inst[6:0] == 7'b0110011) {
            bins add_sub = {3'b000};
            bins sll     = {3'b001};
            bins slt     = {3'b010};
            bins and_    = {3'b111};
            bins or_     = {3'b110};
            bins srl_sra = {3'b101};
        }
        // 3. Branch type coverage
        cp_branch_fun3: coverpoint item.inst[14:12] iff (item.inst[6:0] == 7'b1100011) {
            bins beq = {3'b000};
            bins bne = {3'b001};
            bins blt = {3'b100};
            bins bge = {3'b101};
        }
        // 4. ECC status coverage
        cp_single_err: coverpoint item.single_err_corrected;
        cp_double_err: coverpoint item.double_err_detected;
        cp_mmio: coverpoint item.peripheral_reg_out inside {[0:32'hFFFF_FFFF]};
        // 5. Fault injection position ranges
        cp_fault_pos: coverpoint item.fault_bit_pos iff (item.fault_inject_en) {
            bins data_low  = {[0:11]};
            bins data_mid  = {[12:25]};
            bins data_high = {[26:31]};
            bins parity    = {[32:38]};
        }
        cp_fault_pos2: coverpoint item.fault_bit_pos2 iff (item.fault_inject_en2) {
            bins data_low2  = {[0:11]};
            bins data_mid2  = {[12:25]};
            bins data_high2 = {[26:31]};
            bins parity2    = {[32:38]};
        }

        // Cross coverage of interesting interactions
        cross cp_opcode, cp_single_err;
        cross cp_fault_pos, cp_single_err;

    endgroup

    // ---------------------------------------------------------------
    // Peripheral functional coverage
    // ---------------------------------------------------------------
    covergroup periph_cg with function sample(risc_v_periph_seq_item it);
        // SPI transfer events
        cp_spi_busy:   coverpoint it.spi_busy;
        cp_spi_done:   coverpoint it.spi_done_out;
        cp_spi_rx:     coverpoint it.spi_rx_out iff (it.spi_done_out) {
            bins aa          = {8'hAA};
            bins other_known = default;
        }
        // PWM generation
        cp_pwm_en:     coverpoint (it.pwm_period_out != 0 && it.pwm_duty_out != 0);
        cp_pwm_duty:   coverpoint it.pwm_duty_out {
            bins d3 = {16'd3};
            bins other = {[1:65535]} with (item != 16'd3);
        }
        cp_pwm_period: coverpoint it.pwm_period_out {
            bins p8 = {16'd8};
            bins other = {[1:65535]} with (item != 16'd8);
        }
        cp_pwm_live:   coverpoint it.pwm_out;
        // RPM measurement
        cp_rpm_valid:  coverpoint it.rpm_valid_out;
        cp_rpm_period: coverpoint it.rpm_period_out iff (it.rpm_valid_out) {
            bins p40 = {32'd40};
            bins other = default;
        }
        // profile loading
        cp_profile_loaded: coverpoint it.profile_loaded_out;
        cp_profile_active: coverpoint it.profile_active_out;
        // stall detection
        cp_stall: coverpoint it.stall iff (it.spi_busy);
        // fail-safe behaviour
        cp_failsafe:   coverpoint it.fail_safe_active;
        cp_wdt_timeout: coverpoint it.wdt_timeout_out;
        cp_pwm_under_fs: coverpoint it.pwm_out iff (it.fail_safe_active);

        cross cp_spi_done, cp_spi_rx;
        cross cp_failsafe, cp_pwm_under_fs;
        cross cp_wdt_timeout, cp_failsafe;
    endgroup

    // PC reachability coverage: which instruction addresses were executed
    covergroup pc_cg with function sample(logic [31:0] pc);
        cp_pc: coverpoint pc {
            bins addr_00 = {32'h0000_0000};
            bins addr_04 = {32'h0000_0004};
            bins addr_08 = {32'h0000_0008};
            bins addr_0C = {32'h0000_000C};
            bins addr_10 = {32'h0000_0010};
            bins addr_14 = {32'h0000_0014};
            bins addr_18 = {32'h0000_0018};
            bins addr_1C = {32'h0000_001C};
            bins addr_20 = {32'h0000_0020};
            bins addr_24 = {32'h0000_0024};
            bins addr_28 = {32'h0000_0028};
            bins addr_2C = {32'h0000_002C};
            bins addr_30 = {32'h0000_0030};
            bins addr_34 = {32'h0000_0034};
            bins addr_38 = {32'h0000_0038};
            bins other    = default;
        }
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        instr_cg = new();
        pc_cg    = new();
        periph_cg = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        periph_export = new("periph_export", this);
    endfunction

    function void write_periph(risc_v_periph_seq_item t);
        periph_cg.sample(t);
    endfunction

    function void write(risc_v_seq_item t);
        num_instr++;
        instr_cg.sample(t);
        pc_cg.sample(t.pc);
        if (t.single_err_corrected) num_single_fault++;
        if (t.double_err_detected)  num_double_fault++;
        if (t.peripheral_reg_out != 0) num_mmio_access++;
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("COV", $sformatf("Instructions sampled      : %0d", num_instr), UVM_LOW)
        `uvm_info("COV", $sformatf("Single-bit corrections    : %0d", num_single_fault), UVM_LOW)
        `uvm_info("COV", $sformatf("Double-bit detections     : %0d", num_double_fault), UVM_LOW)
        `uvm_info("COV", $sformatf("MMIO accesses observed    : %0d", num_mmio_access), UVM_LOW)
        `uvm_info("COV", $sformatf("Instr coverage            : %0.1f%%", instr_cg.get_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("PC reachability coverage  : %0.1f%%", pc_cg.get_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("Periph coverage           : %0.1f%%", periph_cg.get_coverage()), UVM_LOW)
    endfunction

endclass

`endif


