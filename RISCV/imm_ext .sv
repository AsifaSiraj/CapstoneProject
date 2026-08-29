module imm_ext (
    output logic [31:0] imm_out,
    input  logic [1:0]  imm_src,
    input  logic [31:0] inst
);
    always_comb begin
        case (imm_src)
            2'b00: imm_out = {{20{inst[31]}}, inst[31:20]};                               // I-type
            2'b01: imm_out = {{20{inst[31]}}, inst[31:25], inst[11:7]};                   // S-type
            2'b10: imm_out = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};    // B-type
            2'b11: imm_out = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};  // J-type
            default: imm_out = '0;
        endcase
    end
endmodule
