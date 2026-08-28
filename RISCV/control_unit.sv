module control_unit (
    output logic       branch,
    output logic       regwrite,
    output logic       memwrite,
    output logic       alu_src,
    output logic       result_src,
    output logic [1:0] imm_src,
    output logic [1:0] aluop,
    input  logic [6:0] opcode
);
    logic [8:0] controls;

    assign {alu_src, result_src, imm_src, regwrite, memwrite, branch, aluop} = controls;

    always_comb begin
        unique case (opcode)
            7'b0110011: controls = 9'b0_0_00_1_0_0_10; // R-type
            7'b0000011: controls = 9'b1_1_00_1_0_0_00; // Load
            7'b0100011: controls = 9'b1_0_01_0_1_0_00; // Store
            7'b1100011: controls = 9'b0_0_10_0_0_1_01; // Branch
            7'b0010011: controls = 9'b1_0_00_1_0_0_10; // I-type
            default:    controls = 9'b0_0_00_0_0_0_00;
        endcase
    end
endmodule