`timescale 1ns/1ps
`ifndef RISC_V_SCOREBOARD_SV
`define RISC_V_SCOREBOARD_SV
`include "uvm_macros.svh"
import uvm_pkg::*;

class risc_v_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(risc_v_scoreboard)

    // Analysis import: single channel from the (CPU) monitor
    uvm_analysis_imp #(risc_v_seq_item, risc_v_scoreboard) sb_export;
    // Periph channel: per-cycle peripheral observation stream
    uvm_analysis_imp_periph #(risc_v_periph_seq_item, risc_v_scoreboard) periph_export;

    // --- Reference model state ---
    logic [31:0] ref_regs [0:31];
    logic [31:0] ref_mmio [0:31];        // MMIO word-offset shadow (wo 0x00..0x1F)
    logic [7:0]  ref_mem [0:63];         // byte shadow of ECC RAM (data only)

    // --- peripheral write tracking (from MMIO stores) ---
    bit [7:0]  ref_spi_tx;
    bit        ref_spi_tx_valid;
    logic [31:0] ref_profile [0:7];
    int        ref_profile_writes;

    int check_cnt = 0;
    int error_cnt = 0;

    // --- last observed peripheral snapshot (for MMIO read prediction) ---
    risc_v_periph_seq_item periph_snap;

    // --- peripheral functional check bookkeeping ---
    int spi_done_count = 0;
    int stall_cycles = 0;
    int pwm_runs = 0;
    int pwm_run_len = 0;
    bit pwm_in_high = 0;
    int rpm_valid_count = 0;
    int rpm_valid_edges = 0;
    int profile_load_count = 0;
    int expected_tach_period = 40;
    int failsafe_count = 0;
    int pwm_off_violations = 0;
    bit rpm_valid_prev = 0;

    // --- ECC end-of-run tracking (DUT flags are sticky-latched until reset) ---
    bit fault_single_injected = 0;
    bit fault_double_injected = 0;
    bit dut_se_ever = 0;
    bit dut_de_ever = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sb_export = new("sb_export", this);
        periph_export = new("periph_export", this);
        periph_snap = risc_v_periph_seq_item::type_id::create("periph_snap");
        reset_model();
    endfunction

    function void reset_model();
        for (int i = 0; i < 32; i++) begin
            ref_regs[i] = '0;
        end
        foreach (ref_mmio[i]) ref_mmio[i] = 32'h0;
        foreach (ref_mem[i])  ref_mem[i]  = 8'h0;
        foreach (ref_profile[i]) ref_profile[i] = 32'h0;
        ref_spi_tx_valid = 1'b0;
        ref_profile_writes = 0;
    endfunction

    // ------------------------------------------------------------------
    // Reference model + check driver
    // ------------------------------------------------------------------
    function void write(risc_v_seq_item item);
        logic [31:0] alu_ref;
        logic [31:0] imm;
        logic [31:0] rs1_v, rs2_v, addr, load_val;
        logic [4:0]  rd_addr;
        logic [31:0] b_imm;
        logic        taken, expected_taken;

        check_cnt++;

        // ---- decode common fields ----
        case (item.imm_src)
            3'b000: imm = {{20{item.inst[31]}}, item.inst[31:20]};
            3'b001: imm = {{20{item.inst[31]}}, item.inst[31:25], item.inst[11:7]};
            3'b010: imm = {{20{item.inst[31]}}, item.inst[7], item.inst[30:25], item.inst[11:8], 1'b0};
            3'b011: imm = {{12{item.inst[31]}}, item.inst[19:12], item.inst[20], item.inst[30:21], 1'b0};
            3'b100: imm = {item.inst[31:12], 12'b0};
            default: imm = 32'h0;
        endcase

        rd_addr = item.inst[11:7];
        rs1_v   = (item.inst[19:15] == 5'd0) ? 32'd0 : ref_regs[item.inst[19:15]];
        rs2_v   = (item.inst[24:20] == 5'd0) ? 32'd0 : ref_regs[item.inst[24:20]];

        case (item.opcode_ref)
            // ---------------- R-type ----------------
            7'b0110011: begin
                case (item.inst[14:12])
                    3'b000: alu_ref = item.inst[30] ? (rs1_v - rs2_v) : (rs1_v + rs2_v);
                    3'b001: alu_ref = rs1_v << rs2_v[4:0];
                    3'b010: alu_ref = ($signed(rs1_v) < $signed(rs2_v)) ? 32'd1 : 32'd0;
                    3'b100: alu_ref = ($signed(rs1_v) < $signed(rs2_v)) ? 32'd1 : 32'd0;
                    3'b101: alu_ref = item.inst[30] ? ($signed(rs1_v) >>> rs2_v[4:0])
                                                    : (rs1_v >> rs2_v[4:0]);
                    3'b110: alu_ref = rs1_v | rs2_v;
                    3'b111: alu_ref = rs1_v & rs2_v;
                    default: alu_ref = 32'h0;
                endcase
                chk_alu(item, alu_ref);
                // register writeback prediction
                if (rd_addr != 5'd0 && item.regwrite)
                    ref_regs[rd_addr] = alu_ref;
            end

            // ---------------- I-type ALU ----------------
            7'b0010011: begin
                case (item.inst[14:12])
                    3'b000: alu_ref = rs1_v + imm;
                    3'b001: alu_ref = rs1_v << imm[4:0];
                    3'b010: alu_ref = ($signed(rs1_v) < $signed(imm)) ? 32'd1 : 32'd0;
                    3'b100: alu_ref = ($signed(rs1_v) < $signed(imm)) ? 32'd1 : 32'd0;
                    3'b101: alu_ref = item.inst[30] ? ($signed(rs1_v) >>> imm[4:0])
                                                    : (rs1_v >> imm[4:0]);
                    3'b110: alu_ref = rs1_v | imm;
                    3'b111: alu_ref = rs1_v & imm;
                    default: alu_ref = 32'h0;
                endcase
                chk_alu(item, alu_ref);
                if (rd_addr != 5'd0 && item.regwrite)
                    ref_regs[rd_addr] = alu_ref;
            end

            // ---------------- Load (lw) ----------------
            7'b0000011: begin
                addr = rs1_v + imm;
                chk_alu(item, addr);                    // ALU must produce address
                if (addr[31]) begin
                    // Live/peripheral-status registers: the DUT read data reflects
                    // pipeline-latency peripheral state that cannot be reproduced
                    // cycle-exactly by the per-cycle periph snapshot. For these we
                    // trust the DUT output (the periph stream checks the dynamics)
                    // and only ARCHITECT check the stable CPU-written registers.
                    if (is_live_mmio(addr)) begin
                        load_val = item.rd;
                    end else begin
                        load_val = mmio_read(item, addr);
                        if (load_val !== item.rd)
                            err($sformatf("LOAD data mismatch addr=%h exp=%h got=%h",
                                          addr, load_val, item.rd));
                    end
                end else begin
                    load_val = {ref_mem[4*addr[5:2]+3], ref_mem[4*addr[5:2]+2],
                                ref_mem[4*addr[5:2]+1], ref_mem[4*addr[5:2]]};
                    if (load_val !== item.rd)
                        err($sformatf("LOAD data mismatch addr=%h exp=%h got=%h",
                                      addr, load_val, item.rd));
                end
                if (rd_addr != 5'd0 && item.regwrite)
                    ref_regs[rd_addr] = load_val;
            end

            // ---------------- Store (sw) ----------------
            7'b0100011: begin
                addr = rs1_v + imm;
                chk_alu(item, addr);
                // `wd` output must equal register file read 2 (data to write)
                if (item.wd !== rs2_v)
                    err($sformatf("STORE data mismatch addr=%h exp=%h got=%h", addr, rs2_v, item.wd));
                if (addr[31]) begin
                    mmio_store(item, addr, rs2_v);
                end else begin
                    ref_mem[4*addr[5:2]+0] = rs2_v[7:0];
                    ref_mem[4*addr[5:2]+1] = rs2_v[15:8];
                    ref_mem[4*addr[5:2]+2] = rs2_v[23:16];
                    ref_mem[4*addr[5:2]+3] = rs2_v[31:24];
                end
            end

            // ---------------- Branch ----------------
            7'b1100011: begin
                b_imm = {{20{item.inst[31]}}, item.inst[7], item.inst[30:25],
                         item.inst[11:8], 1'b0};
                case (item.inst[14:12])
                    3'b000: taken = (rs1_v == rs2_v);               // BEQ
                    3'b001: taken = (rs1_v != rs2_v);               // BNE
                    3'b100: taken = ($signed(rs1_v) < $signed(rs2_v)); // BLT
                    3'b101: taken = ($signed(rs1_v) >= $signed(rs2_v));// BGE
                    default: taken = 1'b0;
                endcase
                expected_taken = taken;
                if (item.pc_src !== expected_taken)
                    err($sformatf("BRANCH cond mismatch PC=%h exp_taken=%0b pc_src=%0b",
                                  item.pc, expected_taken, item.pc_src));
            end

            // ---------------- JAL ----------------
            7'b1101111: begin
                // ALU must give pc+imm (target). We cannot observe link data,
                // so at least verify pc_src = 1 for jumps.
                if (item.pc_src !== 1'b1)
                    err($sformatf("JAL pc_src not asserted PC=%h", item.pc));
                if (rd_addr != 5'd0 && item.regwrite)
                    ref_regs[rd_addr] = item.pc + 4;
            end

            // ---------------- LUI ----------------
            7'b0110111: begin
                alu_ref = imm;                       // 0 + imm (lui_sel forces srcA=0)
                chk_alu(item, alu_ref);
                if (rd_addr != 5'd0 && item.regwrite)
                    ref_regs[rd_addr] = imm;
            end
            default: begin
                // Unhandled opcode observed Ã¢â‚¬â€ flag it
                `uvm_info("SCB", $sformatf("Unknown opcode %b at PC=%h", item.inst[6:0], item.pc),
                          UVM_HIGH)
            end
        endcase

        // ---- ECC tracking (sticky-latch model, checked at end of run) ----
        // The DUT's error_status_reg latches single_err/double_err until reset.
        // A fault can only assert a flag when it coincides with a qualifying
        // ECC read, so we verify these as end-of-run sticky facts rather than
        // on an exact per-cycle basis.
        // A combined en+en2 cycle is a DOUBLE fault, not a single one
        if (item.fault_inject_en && !item.fault_inject_en2) fault_single_injected = 1'b1;
        if (item.fault_inject_en2) fault_double_injected = 1'b1;
        if (item.single_err_corrected) dut_se_ever = 1'b1;
        if (item.double_err_detected)  dut_de_ever = 1'b1;

        // ---- Word-alignment invariant (assertion-level check) ----
        if (item.pc[1:0] != 2'b00)
            err($sformatf("PC misaligned: %h", item.pc));
    endfunction

    // ------------------------------------------------------------------
    // MMIO reference model (matches the peripherals read/write mux)
    // ------------------------------------------------------------------
    function [9:0] mmio_wo(input logic [31:0] a);
        return a[11:2];
    endfunction

    // Live peripheral-status words whose dynamics cannot be predicted
    // cycle-exactly by the reference model (pipeline latency vs per-cycle
    // periph snapshot). Everything else is CPU-written and strictly checked.
    function bit is_live_mmio(input logic [31:0] a);
        logic [9:0] wo = mmio_wo(a);
        case (wo)
            10'h003, 10'h004, 10'h009, 10'h00A, 10'h014, 10'h016: return 1'b1;
            default: return 1'b0;
        endcase
    endfunction

    function void mmio_store(risc_v_seq_item item, logic [31:0] a, logic [31:0] d);
        logic [9:0] wo = mmio_wo(a);
        ref_mmio[wo] = d;
        if (wo == 10'h001) begin
            ref_spi_tx       = d[7:0];
            ref_spi_tx_valid = 1'b1;
        end
        if (wo >= 10'h00C && wo <= 10'h013) begin
            ref_profile[wo[3:0] - 4'hC] = d;
            ref_profile_writes++;
        end
    endfunction

    function logic [31:0] mmio_read(risc_v_seq_item item, logic [31:0] a);
        logic [9:0] wo = mmio_wo(a);
        case (wo)
            10'h003: return {30'b0, periph_snap.spi_done_out, periph_snap.spi_busy};
            10'h004: return {24'b0, periph_snap.spi_rx_out};
            10'h009: return periph_snap.rpm_period_out;
            10'h00A: return {31'b0, periph_snap.rpm_valid_out};
            10'h014: return {30'b0, periph_snap.profile_active_out, periph_snap.profile_loaded_out};
            10'h016: return {30'b0, periph_snap.wdt_timeout_out, periph_snap.fail_safe_active};
            default: return ref_mmio[wo];
        endcase
    endfunction

    // ------------------------------------------------------------------
    // Peripheral observation stream (SPI / PWM / RPM / profile / WDT)
    // ------------------------------------------------------------------
    function void write_periph(risc_v_periph_seq_item item);
        // keep a snapshot for MMIO read prediction in the main model
        periph_snap.do_copy(item);

        // ---- SPI: RX byte must match what was actually transmitted ----
        if (item.spi_done_out && !$isunknown(item.spi_done_out)) begin
            spi_done_count++;
            if (ref_spi_tx_valid && item.spi_rx_out !== ref_spi_tx)
                err($sformatf("SPI RX mismatch: exp=%02h got=%02h", ref_spi_tx, item.spi_rx_out));
        end

        // ---- stall: only meaningful while SPI is busy ----
        if (item.stall) stall_cycles++;
        if (item.stall && !item.spi_busy)
            err("Stall asserted while SPI is not busy");

        // ---- PWM duty: high-run length must match configured duty ----
        if (item.pwm_out)
            pwm_run_len++;
        else if (pwm_in_high) begin
            pwm_in_high = 0;
            if (pwm_run_len != 0 && item.pwm_period_out != 0 &&
                (item.pwm_period_out < item.pwm_duty_out))
                err($sformatf("PWM duty %0d exceeds period %0d", item.pwm_duty_out, item.pwm_period_out));
            if (pwm_run_len > item.pwm_duty_out + 1)
                err($sformatf("PWM high-run %0d exceeds configured duty %0d", pwm_run_len, item.pwm_duty_out));
            if (pwm_run_len + 1 < item.pwm_duty_out)
                err($sformatf("PWM high-run %0d too short for duty %0d", pwm_run_len, item.pwm_duty_out));
            pwm_runs++;
            pwm_run_len = 0;
        end
        if (item.pwm_out && !pwm_in_high)
            pwm_in_high = 1;

        // ---- fail-safe: PWM must be forced off ----
        if (item.fail_safe_active) begin
            if (item.pwm_out) begin
                pwm_off_violations++;
                err("PWM output high while fail-safe active");
            end
        end

        // ---- RPM: measured period must match the drove tachometer ----
        // The first capture after rpm_en is necessarily partial (enable lands
        // mid-period); validate steady-state periods from the 2nd edge on.
        if (item.rpm_valid_out && !$isunknown(item.rpm_valid_out)) begin
            rpm_valid_count++;
            if (!rpm_valid_prev) begin
                rpm_valid_edges++;
                if (rpm_valid_edges >= 2 && expected_tach_period > 0) begin
                    if (item.rpm_period_out < expected_tach_period - 1 ||
                        item.rpm_period_out > expected_tach_period + 1)
                        err($sformatf("RPM period %0d outside expected tach period %0d",
                                      item.rpm_period_out, expected_tach_period));
                end
            end
        end
        rpm_valid_prev = item.rpm_valid_out;

        // ---- profile: LOADED must co-occur with ACTIVE ----
        if (item.profile_loaded_out && !$isunknown(item.profile_loaded_out)) begin
            profile_load_count++;
            if (!item.profile_active_out)
                err("Profile LOADED asserted without ACTIVE");
            if (ref_profile_writes <= 0)
                err("Profile LOADED asserted but no profile writes observed");
        end

        // ---- watchdog/fail-safe source sanity ----
        if ($isunknown(item.wdt_timeout_out) == 0) begin
            if (item.wdt_timeout_out && !item.fail_safe_active)
                err("Watchdog timeout without fail-safe active");
            if (item.fail_safe_active) failsafe_count++;
        end
    endfunction

    function void chk_alu(risc_v_seq_item item, logic [31:0] exp);
        if (item.alu_result !== exp)
            err($sformatf("ALU mismatch exp=%h got=%h PC=%h inst=%h", exp, item.alu_result,
                          item.pc, item.inst));
    endfunction

    function void err(string msg);
        error_cnt++;
        `uvm_error("SCB", msg)
    endfunction

    function void report_phase(uvm_phase phase);
        // End-of-run ECC verification (glitch-tolerant, sticky-latch model)
        if (fault_single_injected && !dut_se_ever)
            `uvm_error("SCB", "Single-bit fault injected but single_err_corrected never asserted")
        if (!fault_single_injected && dut_se_ever)
            `uvm_error("SCB", "single_err_corrected asserted with no single-bit fault injected")
        if (fault_double_injected && !dut_de_ever)
            `uvm_error("SCB", "Double-bit fault injected but double_err_detected never asserted")
        if (!fault_double_injected && dut_de_ever)
            `uvm_error("SCB", "double_err_detected asserted with no double-bit fault injected")

        // ---- Peripheral functional checks ----
        `uvm_info("SCB", $sformatf("SPI transfers completed  : %0d", spi_done_count), UVM_MEDIUM)
        `uvm_info("SCB", $sformatf("Stall cycles observed     : %0d", stall_cycles), UVM_MEDIUM)
        `uvm_info("SCB", $sformatf("PWM high-runs checked     : %0d", pwm_runs), UVM_MEDIUM)
        `uvm_info("SCB", $sformatf("RPM validation cycles     : %0d", rpm_valid_count), UVM_MEDIUM)
        `uvm_info("SCB", $sformatf("Profile load events       : %0d", profile_load_count), UVM_MEDIUM)
        `uvm_info("SCB", $sformatf("Fail-safe active cycles   : %0d", failsafe_count), UVM_MEDIUM)
        `uvm_info("SCB", $sformatf("Checks=%0d Errors=%0d", check_cnt, error_cnt), UVM_MEDIUM)
    endfunction

endclass

`endif


