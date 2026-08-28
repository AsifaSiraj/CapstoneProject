module cu (
    output logic       alu_src,
    output logic       result_src,
    output logic       regwrite,
    output logic       memwrite,
    output logic       pc_src,
    output logic [1:0] imm_src,
    output logic [2:0] alu_control,
    input  logic [6:0] opcode,
    input  logic [2:0] fun3,
    input  logic       fun7,
    input  logic       zero
);
    logic       branch;
    logic [1:0] aluop;

    control_unit C1 (
        .branch(branch), .regwrite(regwrite), .memwrite(memwrite),
        .alu_src(alu_src), .result_src(result_src), .imm_src(imm_src),
        .aluop(aluop), .opcode(opcode)
    );

    alu_control C2 (
        .alu_control(alu_control), .aluop(aluop), .fun3(fun3), .fun7(fun7)
    );

    assign pc_src = branch && zero;
endmodule
