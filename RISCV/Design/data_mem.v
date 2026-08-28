module data_mem(rd,clk,memwrite,addr,wd);

input clk, memwrite;
input [31:0]addr,wd;
output reg [31:0]rd;
reg[7:0] mem[63:0];

integer i;

initial begin
    for (i = 0; i < 64; i = i + 1)
        mem[i] = i;   
end
always @(*) begin
        rd = {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]};
end
always @(posedge clk) begin
        if (memwrite) begin
            mem[addr]     <= wd[7:0];
            mem[addr+1]   <= wd[15:8];
            mem[addr+2]   <= wd[23:16];
            mem[addr+3]   <= wd[31:24];
        end
    end
endmodule

module data_mem_tb;

reg clk,memwrite;
reg [31:0] addr, wd;
wire [31:0] rd;

data_mem MEM(rd,clk,memwrite,addr,wd);

always 
#5 clk = ~clk;   

initial begin

clk = 0;
memwrite = 0;
addr = 0;
wd = 0;
#10;
addr = 0;
wd = 32'hDACBF567;
memwrite = 1;
#10;  
memwrite = 0; 
#10;
addr = 0;
#10;
addr = 4;
wd = 32'hCA30B91E;
memwrite = 1;
#10;
memwrite = 0;
#10;
addr = 4;
#10;
$stop;
end
initial $monitor("time=%0t addr=%0d wd=%h memwrite=%b rd=%h",$time, addr, wd, memwrite, rd);
endmodule

