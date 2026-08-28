module alu (
    output logic [31:0] result,
    output logic        zero,
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [2:0]  alu_control
);
    always_comb begin
        case (alu_control)
            3'd0: result = a + b;
            3'd1: result = a - b;
            3'd2: result = a & b;
            3'd3: result = a | b;
            3'd4: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            3'd5: result = a <<  b[4:0];
            3'd6: result = a >>  b[4:0];
            3'd7: result = $signed(a) >>> b[4:0];
            default: result = 32'h0;
        endcase
        zero = (a == b);
    end
endmodule
