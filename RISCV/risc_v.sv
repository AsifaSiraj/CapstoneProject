module risc_v (
    input  logic        clk,
    input  logic        reset,
    // ---- fault injection ----
    input  logic        fault_inject_en,
    input  logic [5:0]  fault_bit_pos,
    input  logic        fault_inject_en2,
    input  logic [5:0]  fault_bit_pos2,
    // ---- observation outputs ----
    output logic        result_src,
    output logic        memwrite,
    output logic        alu_src,
    output logic        regwrite,
    output logic        pc_src,
    output logic [1:0]  imm_src,
    output logic [31:0] pc,
    output logic [31:0] inst,
    output logic [31:0] alu_result,
    output logic [31:0] wd,
    output logic [31:0] rd,
    // ---- ECC & MMIO Status ----
    output logic        single_err_corrected,
    output logic        double_err_detected,
    output logic [31:0] error_addr,
    output logic [31:0] peripheral_reg_out
);
    logic [31:0] pc_next, pc_4, pc_target;
    logic [31:0] rd1, rd2, result;
    logic [31:0] imm_ext_w, src_b, read_data;
    logic [2:0]  alu_ctrl;
    logic        zero, sign;

    // Fetch
    mux       PC_next   (.y(pc_next), .sel(pc_src), .a(pc_4), .b(pc_target));
    pc        ProgC     (.clk(clk), .reset(reset), .x(pc_next), .out(pc));
    adder     pc_plus4  (.c(pc_4), .a(pc), .b(32'd4));
    instr_mem IM        (.addr(pc), .inst(inst));

    // Decode / Execute
    reg_file RF (
        .rd1(rd1), .rd2(rd2),
        .rs1(inst[19:15]), .rs2(inst[24:20]), .rd(inst[11:7]),
        .wd(result), .regwrite(regwrite), .clk(clk), .reset(reset)
    );

    imm_ext ImmExt (.imm_out(imm_ext_w), .imm_src(imm_src), .inst(inst));
    mux     SRC_B  (.y(src_b), .sel(alu_src), .a(rd2), .b(imm_ext_w));
    alu     ALU    (.result(alu_result), .zero(zero), .sign(sign), .a(rd1), .b(src_b), .alu_control(alu_ctrl));
    adder   PC_target (.c(pc_target), .a(pc), .b(imm_ext_w));

    cu CU (
        .alu_src(alu_src), .result_src(result_src), .regwrite(regwrite),
        .memwrite(memwrite), .pc_src(pc_src), .imm_src(imm_src),
        .alu_control(alu_ctrl),
        .opcode(inst[6:0]), .fun3(inst[14:12]), .fun7(inst[30]),
        .zero(zero), .sign(sign)
    );

    // Memory-Mapped Peripheral & Memory Interconnect
    sys_bus BUS (
        .clk                 (clk),
        .reset               (reset),
        .memwrite            (memwrite),
        .addr                (alu_result),
        .write_data          (rd2),
        .read_data           (read_data),
        .fault_inject_en     (fault_inject_en),   .fault_bit_pos(fault_bit_pos),
        .fault_inject_en2    (fault_inject_en2), .fault_bit_pos2(fault_bit_pos2),
        .single_err_corrected(single_err_corrected),
        .double_err_detected (double_err_detected),
        .error_addr          (error_addr),
        .peripheral_reg_out  (peripheral_reg_out)
    );

    // Write-back
    mux result_mux (.y(result), .sel(result_src), .a(alu_result), .b(read_data));

    assign wd = rd2;
    assign rd = read_data;
endmodule
