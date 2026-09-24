`timescale 1ns/1ps
`ifndef RISC_V_TEST_SV
`define RISC_V_TEST_SV
`include "uvm_macros.svh"
import uvm_pkg::*;

// ------------------------------------------------------------------
// Base test with clock / reset generation
// ------------------------------------------------------------------
class risc_v_base_test extends uvm_test;

    `uvm_component_utils(risc_v_base_test)

    risc_v_env env;
    virtual risc_v_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = risc_v_env::type_id::create("env", this);
        if (!uvm_config_db#(virtual risc_v_if)::get(this, "", "vif", vif))
            `uvm_fatal("TB", "No virtual interface configured")
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        reset_dut();
        fork
            begin run_seq();            end
            begin run_periph_seq();     end
        join
        #1000;
        phase.drop_objection(this);
    endtask

    // Apply a clean reset sequence
    virtual task reset_dut();
        vif.reset = 1;
        vif.fault_inject_en  <= 0;
        vif.fault_bit_pos    <= '0;
        vif.fault_inject_en2 <= 0;
        vif.fault_bit_pos2   <= '0;
        repeat(3) @(posedge vif.clk);
        vif.reset = 0;
        repeat(2) @(posedge vif.clk);
        `uvm_info("TEST", "Reset completed", UVM_MEDIUM)
    endtask

    // Peripheral world stimulus: rotor running at 40-clk period, SPI loopback
    virtual task run_periph_seq();
        risc_v_periph_default_seq pseq;
        pseq = risc_v_periph_default_seq::type_id::create("pseq");
        pseq.tach_period = 40;
        void'(pseq.randomize());
        pseq.start(env.p_agt.sqr);
        env.scb.expected_tach_period = 40;
    endtask

    virtual task run_seq();
        risc_v_golden_seq seq;
        seq = risc_v_golden_seq::type_id::create("seq");
        seq.num_cycles = 30;
        seq.start(env.agt.sqr);
    endtask

    function void report_phase(uvm_phase phase);
        uvm_report_server srv = uvm_report_server::get_server();
        if (srv.get_severity_count(UVM_FATAL) + srv.get_severity_count(UVM_ERROR) == 0)
            `uvm_info("TEST", "*** TEST PASSED ***", UVM_LOW)
        else
            `uvm_error("TEST", "*** TEST FAILED ***")
    endfunction

endclass

// ------------------------------------------------------------------
// Test 1: Golden run (no faults) - verify nominal RISC-V execution
// ------------------------------------------------------------------
class risc_v_golden_test extends risc_v_base_test;
    `uvm_component_utils(risc_v_golden_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_seq();
        risc_v_golden_seq seq;
        seq = risc_v_golden_seq::type_id::create("seq");
        seq.num_cycles = 40;
        seq.start(env.agt.sqr);
    endtask
endclass

// ------------------------------------------------------------------
// Test 2: Single-bit ECC fault test (SEC must correct, data intact)
// ------------------------------------------------------------------
class risc_v_single_bit_test extends risc_v_base_test;
    `uvm_component_utils(risc_v_single_bit_test)

    rand logic [5:0] bit_pos;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        void'(randomize());
    endfunction

    constraint c_pos { bit_pos inside {[0:38]}; }

    virtual task run_seq();
        risc_v_single_bit_fault_seq seq;
        seq = risc_v_single_bit_fault_seq::type_id::create("seq");
        seq.fault_bit_pos = bit_pos;
        seq.start(env.agt.sqr);
        `uvm_info("TEST", $sformatf("Single-bit fault injected at bit %0d", bit_pos), UVM_LOW)
    endtask
endclass

// ------------------------------------------------------------------
// Test 3: Double-bit ECC fault test (DED must assert)
// ------------------------------------------------------------------
class risc_v_double_bit_test extends risc_v_base_test;
    `uvm_component_utils(risc_v_double_bit_test)

    rand logic [5:0] bit_pos;
    rand logic [5:0] bit_pos2;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        void'(randomize());
    endfunction

    constraint c_pos {
        bit_pos  inside {[0:38]};
        bit_pos2 inside {[0:38]};
        bit_pos != bit_pos2;
    }

    virtual task run_seq();
        risc_v_double_bit_fault_seq seq;
        seq = risc_v_double_bit_fault_seq::type_id::create("seq");
        seq.fault_bit_pos  = bit_pos;
        seq.fault_bit_pos2 = bit_pos2;
        seq.start(env.agt.sqr);
        `uvm_info("TEST", $sformatf("Double-bit fault at bits %0d,%0d", bit_pos, bit_pos2), UVM_LOW)
    endtask
endclass

// ------------------------------------------------------------------
// Test 4: Random stress - broad fault injection sweep
// ------------------------------------------------------------------
class risc_v_stress_test extends risc_v_base_test;
    `uvm_component_utils(risc_v_stress_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_seq();
        risc_v_random_stress_seq seq;
        seq = risc_v_random_stress_seq::type_id::create("seq");
        void'(seq.randomize());
        seq.start(env.agt.sqr);
    endtask
endclass

// ------------------------------------------------------------------
// Test 5: MMIO test - validate peripheral register path at 0x80000000
// ------------------------------------------------------------------
class risc_v_mmio_test extends risc_v_base_test;
    `uvm_component_utils(risc_v_mmio_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_seq();
        risc_v_mmio_seq seq;
        seq = risc_v_mmio_seq::type_id::create("seq");
        seq.num_cycles = 20;
        seq.start(env.agt.sqr);
    endtask
endclass

// ------------------------------------------------------------------
// Test 6: Peripheral test - full SoC program exercising SPI loopback,
//         PWM generation, RPM measurement and profile loading
// ------------------------------------------------------------------
class risc_v_periph_test extends risc_v_base_test;
    `uvm_component_utils(risc_v_periph_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_seq();
        risc_v_golden_seq seq;
        seq = risc_v_golden_seq::type_id::create("seq");
        seq.num_cycles = 300;          // long enough for the full program
        seq.start(env.agt.sqr);
    endtask
endclass

// ------------------------------------------------------------------
// Test 7: Fail-safe test - rotor stops after the program arms the
//         watchdog; WDT must time out, latch fail-safe, force PWM off
// ------------------------------------------------------------------
class risc_v_failsafe_test extends risc_v_base_test;
    `uvm_component_utils(risc_v_failsafe_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_seq();
        risc_v_golden_seq seq;
        seq = risc_v_golden_seq::type_id::create("seq");
        seq.num_cycles = 800;          // WDT times out ~256 clk after stall
        seq.start(env.agt.sqr);
    endtask

    virtual task run_periph_seq();
        risc_v_watchdog_failsafe_seq pseq;
        pseq = risc_v_watchdog_failsafe_seq::type_id::create("pseq");
        void'(pseq.randomize());
        pseq.start(env.p_agt.sqr);
        env.scb.expected_tach_period = 40;
    endtask
endclass

`endif


