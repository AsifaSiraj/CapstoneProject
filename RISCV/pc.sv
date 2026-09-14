module pc (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] x,
    output logic [31:0] out
);
    always_ff @(posedge clk or posedge reset) begin
        if (reset) out <= 32'd0;
        else       out <= x;
    end
endmodule
