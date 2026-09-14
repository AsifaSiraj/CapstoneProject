module imm_ext (
    output logic [31:0] imm_out,
    input  logic [2:0]  imm_src,   
    input  logic [31:0] inst
);
    always_comb begin
        case (imm_src)
            3'b000: imm_out = {{20{inst[31]}}, inst[31:20]};                              // I-type
            3'b001: imm_out = {{20{inst[31]}}, inst[31:25], inst[11:7]};                  // S-type
            3'b010: imm_out = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};   // B-type
            3'b011: imm_out = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0}; // J-type
            3'b100: imm_out = {inst[31:12], 12'b0};                                       // U-type (LUI)
            default: imm_out = '0;
        endcase
    end
endmodule
