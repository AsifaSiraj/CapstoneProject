module risc_v_tb;
    logic        clk, reset;
    logic        fault_en, fault_en2;
    logic [5:0]  fbit0, fbit1;
    logic        result_src, memwrite, alu_src, regwrite, pc_src;
    logic [2:0]  imm_src;
    logic [31:0] pc, inst, alu_result, wd, rd;
    logic        single_err, double_err;
    logic [31:0] error_addr, peripheral_reg_out;

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
        .peripheral_reg_out(peripheral_reg_out)
    );

    always #5 clk = ~clk;

    task automatic check(string name, bit cond);
        if (cond) begin pass_cnt++; $display("[PASS] %s", name); end
        else      begin fail_cnt++; $display("[FAIL] %s", name); end
    endtask

    initial begin
        clk = 0; reset = 1;
        fault_en = 0; fault_en2 = 0; fbit0 = '0; fbit1 = '0;
        #20 reset = 0;

        // Let the full program run (load/store, LUI, JAL, MMIO) — 15 instructions
        #300;

        // ---- Load/Store checks ----
        check("x7 = 200 (2nd lw returned correct stored value)",
              DUT.RF.regs[7] === 32'd200);

        // ---- LUI check ----
        check("x8 = 0x12345000 (LUI loaded upper immediate correctly)",
              DUT.RF.regs[8] === 32'h12345000);

        // ---- JAL checks ----
        check("x9 = 0x28 (JAL saved correct return address pc+4)",
              DUT.RF.regs[9] === 32'h00000028);
        check("x10 = 0 (instruction at 0x28 was correctly SKIPPED by JAL)",
              DUT.RF.regs[10] === 32'd0);

        // ---- MMIO checks ----
        check("peripheral_reg_out = 200 (MMIO write via sw succeeded)",
              peripheral_reg_out === 32'd200);
        check("x12 = 200 (MMIO read-back via lw succeeded)",
              DUT.RF.regs[12] === 32'd200);

        // ---- ECC: confirm no false errors during normal + MMIO execution ----
        check("No false ECC errors during normal run (incl. MMIO access)",
              single_err === 1'b0 && double_err === 1'b0);

        // ============ Fault injection round 1: single-bit (bit-1) error ============
        reset = 1; #20 reset = 0;
        fault_en = 1; fbit0 = 6'd12;   // flip 1 bit in the stored codeword
        #300;
        check("Bit-1 fault: single_err_corrected asserted, double_err stays low",
              single_err === 1'b1 && double_err === 1'b0);
        check("Bit-1 fault: x7 still correctly = 200 (data transparently corrected)",
              DUT.RF.regs[7] === 32'd200);
        fault_en = 0;

        // ============ Fault injection round 2: double-bit (bit-2) error ============
        reset = 1; #20 reset = 0;
        fault_en = 1; fbit0 = 6'd4; fault_en2 = 1; fbit1 = 6'd20;
        #300;
        check("Bit-2 fault: double_err_detected asserted",
              double_err === 1'b1);
        fault_en = 0; fault_en2 = 0;

        $display("\n==== RESULT: %0d PASSED / %0d FAILED ====", pass_cnt, fail_cnt);
        $stop;
    end

    initial begin
        $display("  time  |   PC     |   INST   |  ALU     |  WD      |  RD      | RegW MemW | SE DE | MMIO");
        $monitor("%7t | %h | %h | %h | %h | %h |  %b    %b  |  %b  %b | %h",
                 $time, pc, inst, alu_result, wd, rd, regwrite, memwrite,
                 single_err, double_err, peripheral_reg_out);
    end
endmodule
