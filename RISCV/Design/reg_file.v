module reg_file(rd1,rd2,rs1,rs2,rd,wd,regwrite,clk);

input [4:0] rs1, rs2, rd;
input clk, regwrite;
input [31:0] wd;
output [31:0] rd1, rd2;

reg [31:0] regs [0:31];
integer i;

initial begin
   for (i = 0; i < 32; i = i + 1)
       regs[i] = i;
end

assign rd1 = regs[rs1];
assign rd2 = regs[rs2];


    always @(posedge clk) begin
        if (regwrite && rd != 0) begin
            regs[rd] <= wd;
            $strobe("WRITE @%0t rd=%0d wd=%h", $time, rd, wd);
        end
    end
endmodule

module reg_file_tb;
reg [4:0] rs1, rs2, rd;
reg clk, regwrite;
reg [31:0] wd;
wire [31:0] rd1, rd2;

reg_file REG(rd1, rd2, rs1, rs2, rd, wd, regwrite, clk);

initial clk = 0;
always #5 clk = ~clk;

initial begin
regwrite = 1'b1;
wd = 32'hA4562D47; rd = 5'd6; #10;  // write to x6
rs1 = 5'd6;

wd = 32'hDEADBEEF; rd = 5'd4; rs2 = 5'd4; #10; // write to x4
regwrite = 1'b0;
wd = 32'h12345678; rd = 5'd5; rs1 = 5'd5; rs2 = 5'd4; #10; // no write

regwrite = 1'b1;
wd = 32'hCAFEBABE; rd = 5'd7; #10; // write to x7
rs1 = 5'd7; rs2 = 5'd6; #10;

$stop;
end
initial
$monitor("t=%0t | rs1=%0d rd1=%h | rs2=%0d rd2=%h",$time, rs1, rd1, rs2, rd2);
endmodule
