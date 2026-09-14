module adder (
    output logic [31:0] c,
    input  logic [31:0] a,
    input  logic [31:0] b
);
    assign c = a + b;
endmodule

