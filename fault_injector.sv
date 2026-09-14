module fault_injector (
    input  logic [38:0] codeword_in,
    input  logic        fault_inject_en,    // bit-1 error enable
    input  logic [5:0]  fault_bit_pos,      // bit-1 position (0..38)
    input  logic        fault_inject_en2,   // bit-2 error enable
    input  logic [5:0]  fault_bit_pos2,     // bit-2 position (0..38)
    output logic [38:0] codeword_out
);
    logic [38:0] fault_mask;

    always_comb begin
        fault_mask = 39'b0;
        if (fault_inject_en)  fault_mask |= (39'b1 << fault_bit_pos);
        if (fault_inject_en2) fault_mask |= (39'b1 << fault_bit_pos2);
        codeword_out = codeword_in ^ fault_mask;
    end
endmodule
