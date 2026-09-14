module cu (
    output logic       alu_src,
    output logic       result_src,
    output logic       regwrite,
    output logic       memwrite,
    output logic       pc_src,
    output logic       jump,       
    output logic       lui_sel,    
    output logic [2:0] imm_src,   
    output logic [2:0] alu_control,
    input  logic [6:0] opcode,
    input  logic [2:0] fun3,
    input  logic       fun7,
    input  logic       zero,
    input  logic       sign
);
    logic       branch;
    logic [1:0] aluop;
    logic       branch_taken;

    control_unit C1 (
        .jump       (jump),
        .branch     (branch),
        .regwrite   (regwrite),
        .memwrite   (memwrite),
        .alu_src    (alu_src),
        .result_src (result_src),
        .lui_sel    (lui_sel),
        .imm_src    (imm_src),
        .aluop      (aluop),
        .opcode     (opcode)
    );

    alu_control C2 (
        .alu_control (alu_control),
        .aluop       (aluop),
        .fun3        (fun3),
        .fun7        (fun7)
    );

    // Branch condition decode — only meaningful when branch=1
    always_comb begin
        case (fun3)
            3'b000:  branch_taken = zero;   // BEQ
            3'b001:  branch_taken = ~zero;  // BNE
            3'b100:  branch_taken = sign;   // BLT
            3'b101:  branch_taken = ~sign;  // BGE
            default: branch_taken = 1'b0;
        endcase
    end

    assign pc_src = jump ? 1'b1 : (branch ? branch_taken : 1'b0);
endmodule

