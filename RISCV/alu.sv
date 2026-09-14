module alu (
    output logic [31:0] result,
    output logic        zero,
    output logic        sign,
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [2:0]  alu_control
);
    always_comb begin
        case (alu_control)
            3'd0: result = a + b;                                    // ADD
            3'd1: result = a - b;                                    // SUB
            3'd2: result = a & b;                                    // AND
            3'd3: result = a | b;                                    // OR
            3'd4: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;// SLT
            3'd5: result = a <<  b[4:0];                             // SLL
            3'd6: result = a >>  b[4:0];                             // SRL
            3'd7: result = $signed(a) >>> b[4:0];                    // SRA
            default: result = 32'h0;
        endcase
        zero = (result == 32'd0);
        sign = result[31];
    end
endmodule
