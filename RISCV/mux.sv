module mux (
    output logic [31:0] y,
    input  logic        sel,
    input  logic [31:0] a,
    input  logic [31:0] b
);
    always_comb begin
        if (sel) y = b;
        else     y = a;
    end
endmodule

