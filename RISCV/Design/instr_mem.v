module instr_mem (addr,inst);
input  [31:0] addr;
output reg [31:0] inst;
reg [7:0] mem [63:0];  
integer i;

initial begin
// addr 0x00 : addi x27, x0, 0x3C
mem[0] = 8'h93; mem[1] = 8'h0D; mem[2] = 8'hC0; mem[3] = 8'h03;
// addr 0x04 : addi x28, x0, 0xAA
mem[4] = 8'h13; mem[5] = 8'h0E; mem[6] = 8'hA0; mem[7] = 8'h0A;
// addr 0x08 : addi x29, x0, 0x141
mem[8] = 8'h93; mem[9] = 8'h0E; mem[10] = 8'h40; mem[11] = 8'h14;
// addr 0x0C : sb x28, 0(x27)
mem[12] = 8'h23; mem[13] = 8'h80; mem[14] = 8'hCE; mem[15] = 8'h01;
// addr 0x10 : sb x29, 1(x27)
mem[16] = 8'hA3; mem[17] = 8'h80; mem[18] = 8'hDE; mem[19] = 8'h01;
// addr 0x14 : lb x30, 2(x27)
mem[20] = 8'h03; mem[21] = 8'h8F; mem[22] = 8'h2D; mem[23] = 8'h00;
// addr 0x1C : bne x30, x0, -8
mem[24] = 8'hE3; mem[25] = 8'h18; mem[26] = 8'h70; mem[27] = 8'hFF;

end

always @(addr)
inst = {mem[addr+3],mem[addr+2],mem[addr+1],mem[addr]};
endmodule

module instr_mem_tb;
reg  [31:0] addr;
wire [31:0] inst;

instr_mem INST_MEM(addr,inst);

initial begin
$display("Time\tAddr\tInstruction");
$monitor("%0t\t%h\t%h", $time, addr, inst);

addr = 32'h0000_0000; #10;  
addr = 32'h0000_0004; #10; 
addr = 32'h0000_0018; #10;   
addr = 32'h0000_0008; #10;  
addr = 32'h0000_0024; #10;   
addr = 32'h0000_0014; #10;  
addr = 32'h0000_0010; #10; 
addr = 32'h0000_001C; #10;  
addr = 32'h0000_0020; #10;  
addr = 32'h0000_000C; #10;
addr = 32'h0000_0030; #10;  

$stop;
end
endmodule