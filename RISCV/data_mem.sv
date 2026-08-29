module data_mem (
    input  logic        clk,
    input  logic        memwrite,
    input  logic [31:0] addr,
    input  logic [31:0] wd,
    input  logic [2:0]  funct3,   // decodes access width: byte/half/word, signed/unsigned
    output logic [31:0] rd
);

logic [7:0] mem [0:63];

initial begin
    for (int i = 0; i < 64; i++)
        mem[i] = 8'h00;
end

// BUG FIX (carried over from the .v version): the original design always read/wrote
// a full 32-bit word at [addr..addr+3] regardless of instruction width. For sb/lb
// (byte ops), this corrupted adjacent bytes on store and could index past the array
// on the last valid address (addr+3 out of range). Width is now decoded from funct3,
// matching real RV32I load/store encoding:
//   000 = byte  (signed)   LB/SB
//   001 = half  (signed)   LH/SH
//   010 = word              LW/SW
//   100 = byte  (unsigned) LBU
//   101 = half  (unsigned) LHU
logic [31:0] word_read;
logic [15:0] half_read;
logic [7:0]  byte_read;

assign word_read = {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]};
assign half_read = {mem[addr+1], mem[addr]};
assign byte_read = mem[addr];

always_comb begin
    unique case (funct3)
        3'b000:  rd = {{24{byte_read[7]}},  byte_read};   // LB  (sign-extend)
        3'b001:  rd = {{16{half_read[15]}}, half_read};   // LH  (sign-extend)
        3'b010:  rd = word_read;                           // LW
        3'b100:  rd = {24'b0, byte_read};                  // LBU (zero-extend)
        3'b101:  rd = {16'b0, half_read};                  // LHU (zero-extend)
        default: rd = word_read;
    endcase
end

always_ff @(posedge clk) begin
    if (memwrite) begin
        unique case (funct3)
            3'b000: mem[addr] <= wd[7:0];                                     // SB
            3'b001: begin
                mem[addr]   <= wd[7:0];
                mem[addr+1] <= wd[15:8];
            end                                                                // SH
            default: begin                                                     // SW
                mem[addr]   <= wd[7:0];
                mem[addr+1] <= wd[15:8];
                mem[addr+2] <= wd[23:16];
                mem[addr+3] <= wd[31:24];
            end
        endcase
    end
end

endmodule
