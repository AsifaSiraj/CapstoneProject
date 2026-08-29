module risc_v_tb;
    logic        clk, reset;
    logic        fault_en, fault_en2;
    logic [5:0]  fbit0, fbit1;
    logic        result_src, memwrite, alu_src, regwrite, pc_src;
    logic [1:0]  imm_src;
    logic [31:0] pc, inst, alu_result, wd, rd;
    logic        single_err, double_err;
    logic [31:0] error_addr;
    logic [31:0] peripheral_reg_out;

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

    initial begin
        clk = 0; reset = 1;
        fault_en = 0; fault_en2 = 0; fbit0 = '0; fbit1 = '0;

        #20 reset = 0;

        // ---------- Run 1: Normal Program Execution ----------
        #200;
        if (DUT.RF.regs[7] === 32'd200)
            $display("[PASS] Program execution: x7 = %0d (lw returned stored RAM value)", DUT.RF.regs[7]);
        else
            $display("[FAIL] Program execution: x7 = %0d, expected 200", DUT.RF.regs[7]);

        // ---------- Run 2: Single-bit Fault Injection ----------
        fault_en = 1; fbit0 = 6'd12;
        #40;
        if (single_err === 1'b1 && double_err === 1'b0)
            $display("[PASS] Single-bit fault detected & corrected, error_addr=%h", error_addr);
        else
            $display("[FAIL] Single-bit fault logic failed");
        fault_en = 0;

        $stop;
    end
endmodule
