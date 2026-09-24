// ======================================================================
// risc_v_tb.sv - Basic directed, self-checking SystemVerilog testbench
// (non-UVM). Runs the full on-chip program and checks the RISC-V core,
// ECC memory, MMIO, SPI loopback, PWM, RPM, profile loading, stall
// detection and fail-safe (watchdog + ECC-triggered) behaviour.
// ======================================================================
module risc_v_tb;
    logic        clk, reset;
    logic        fault_en, fault_en2;
    logic [5:0]  fbit0, fbit1;
    logic        result_src, memwrite, alu_src, regwrite, pc_src;
    logic [2:0]  imm_src;
    logic [31:0] pc, inst, alu_result, wd, rd;
    logic        single_err, double_err;
    logic [31:0] error_addr, peripheral_reg_out;
    logic        tach_in_ = 0;
    logic        spi_miso_;
    logic        spi_sck, spi_mosi, spi_cs, pwm_out, spi_busy, stall, fail_safe_active;
    logic        tach_run = 1;
    int          tach_cnt = 0;
    logic        saw_stall = 0;
    logic        pwm_saw_high = 0, pwm_saw_low = 0;

    int pass_cnt = 0, fail_cnt = 0;

    risc_v DUT (
        .clk(clk), .reset(reset),
        .fault_inject_en(fault_en),   .fault_bit_pos(fbit0),
        .fault_inject_en2(fault_en2), .fault_bit_pos2(fbit1),
        .result_src(result_src), .memwrite(memwrite), .alu_src(alu_src),
        .regwrite(regwrite), .pc_src(pc_src), .imm_src(imm_src),
        .pc(pc), .inst(inst), .alu_result(alu_result), .wd(wd), .rd(rd),
        .single_err_corrected(single_err),
        .double_err_detected(double_err),
        .error_addr(error_addr),
        .peripheral_reg_out(peripheral_reg_out),
        .tach_in(tach_in_),
        .spi_miso(spi_miso_),
        .spi_sck(spi_sck),
        .spi_mosi(spi_mosi),
        .spi_cs(spi_cs),
        .pwm_out(pwm_out),
        .spi_busy(spi_busy),
        .stall(stall),
        .fail_safe_active(fail_safe_active)
    );

    assign spi_miso_ = spi_mosi;      // SPI loopback: RX == TX

    always #5 clk = ~clk;

    // tach generator: free-running pulse with period 40 clk (when enabled)
    always @(posedge clk) begin
        if (reset) begin
            tach_in_ <= 1'b0;
            tach_cnt <= 0;
        end
        else if (!tach_run) begin
            tach_in_ <= 1'b0;
        end
        else if (tach_cnt == 19) begin
            tach_in_ <= ~tach_in_;
            tach_cnt <= 0;
        end
        else begin
            tach_cnt <= tach_cnt + 1;
        end
    end

    always @(posedge clk) begin
        if (stall)                              saw_stall = 1;
        if (pwm_out)                            pwm_saw_high = 1;
        else                                    pwm_saw_low  = 1;
    end

    task automatic check(string name, bit cond);
        if (cond) begin pass_cnt++; $display("[PASS] %s", name); end
        else      begin fail_cnt++; $display("[FAIL] %s", name); end
    endtask

    // Run one program pass and report key register values
    task automatic run_pass(input string tag, input int wait_ns);
        $display("--- %s: program run ---", tag);
        reset = 1; #20 reset = 0;
        #(wait_ns);
    endtask

    integer pwm_high, pwm_tot;

    initial begin
        clk = 0; reset = 1;
        fault_en = 0; fault_en2 = 0; fbit0 = '0; fbit1 = '0;

        $timeformat(-9, 0, " ns", 4);

        // ============ 1) NORMAL RUN: core + ECC + MMIO + peripherals ============
        run_pass("normal", 1300);

        check("x5 = 0x80000000 (MMIO base via LUI)",
              DUT.RF.regs[5] === 32'h80000000);
        check("peripheral_reg_out = 200 (MMIO sw)",
              peripheral_reg_out === 32'd200);

        // ECC RAM round-trip: stored codewords non-zero (sw performed)
        check("ECC RAM MEM[0] written (codeword non-zero)",
              DUT.BUS.RAM.mem[0] !== 39'b0);
        check("ECC RAM MEM[4] written (codeword non-zero)",
              DUT.BUS.RAM.mem[1] !== 39'b0);

        // SPI: loopback RX equals TX byte 0xAA
        check("SPI_RXD = 0xAA (MOSI->MISO loopback)", DUT.BUS.PERIPH.spi_rx_reg === 8'hAA);
        check("SPI transaction completed (DONE sticky)", DUT.BUS.PERIPH.spi_done === 1'b1);
        check("SPI was observed busy during transfer", saw_stall === 1'b1 || DUT.BUS.PERIPH.spi_busy === 1'b1);

        // stall detection: a poll of a busy SPI asserted stall at least once
        check("stall asserted during SPI busy-wait", saw_stall === 1'b1);

        // PWM: period=8, duty=3 => ~37.5% high over a full-period window
        pwm_high = 0; pwm_tot  = 0;
        begin : pwm_measure
            int k;
            for (k = 0; k < 80; k++) begin
                @(posedge clk);
                pwm_tot++;
                if (pwm_out) pwm_high++;
            end
        end
        check("PWM duty ~37.5% (measured 80 cycles)", pwm_total_chk(pwm_high, pwm_tot));
        check("PWM toggles high and low", pwm_saw_high === 1'b1 && pwm_saw_low === 1'b1);

        // RPM measurement: tach period 40 clk
        check("RPM_PERIOD = 40 (tach period)", DUT.BUS.PERIPH.rpm_period_reg === 32'd40);
        check("RPM_VALID latched", DUT.BUS.PERIPH.rpm_valid_reg === 1'b1);

        // profile loading
        check("PROFILE[0] = 1", DUT.BUS.PERIPH.profile_mem[0] === 32'd1);
        check("PROFILE[7] = 8", DUT.BUS.PERIPH.profile_mem[7] === 32'd8);
        check("PROFILE_LOADED = 1", DUT.BUS.PERIPH.profile_loaded_reg === 32'd1);
        check("PROFILE_ACTIVE = 1", DUT.BUS.PERIPH.profile_active_reg === 32'd1);

        // fail-safe: tach still running -> WDT must NOT trip yet
        check("no fail-safe with running tach", fail_safe_active === 1'b0);

        // No ECC errors in normal run
        check("no false ECC errors in normal run", single_err === 1'b0 && double_err === 1'b0);

        // ============ 2) SINGLE-BIT ECC fault ============
        run_pass("single-bit fault", 1300);
        fault_en = 1; fbit0 = 6'd12;
        #1300;
        check("single-bit: single_err_corrected = 1", single_err === 1'b1);
        check("single-bit: double_err stays 0", double_err === 1'b0);
        check("single-bit: fail-safe NOT triggered (correctable)",
              fail_safe_active === 1'b0);
        fault_en = 0;

        // ============ 3) DOUBLE-BIT ECC fault -> fail-safe ============
        run_pass("double-bit fault", 1300);
        fault_en = 1; fbit0 = 6'd4; fault_en2 = 1; fbit1 = 6'd20;
        #1300;
        check("double-bit: double_err_detected = 1", double_err === 1'b1);
        check("double-bit: FAIL-SAFE latched (uncorrectable ECC)", fail_safe_active === 1'b1);
        check("fail-safe forces PWM output off", pwm_out === 1'b0);
        fault_en = 0; fault_en2 = 0;

        // ============ 4) WATCHDOG fail-safe (tach stops) ============
        // Program must reach FS_CTRL first (requires VALID rpm while tach is
        // running), then the rotor stops and the WDT must time out (256 clk).
        run_pass("watchdog", 1600);
        tach_run = 0;               // rotor stopped after WDT enabled
        #3500;
        check("WDT timeout latched", DUT.BUS.PERIPH.wdt_timeout_reg === 1'b1);
        check("WDT triggers FAIL-SAFE", fail_safe_active === 1'b1);
        check("fail-safe keeps PWM disabled", pwm_out === 1'b0);

        $display("\n==== RESULT: %0d PASSED / %0d FAILED ====", pass_cnt, fail_cnt);
        if (fail_cnt == 0) $display("*** BASIC TESTBENCH PASSED ***");
        else               $display("*** BASIC TESTBENCH FAILED ***");
        $stop;
    end

    function automatic bit pwm_total_chk(input integer h, input integer t);
        // expect duty = 3/8 = 0.375; tolerance +/- 0.125 (one period of 8)
        real ratio;
        ratio = (t == 0) ? 0.0 : real'(h) / real'(t);
        return (ratio > 0.245 && ratio < 0.505);
    endfunction

endmodule