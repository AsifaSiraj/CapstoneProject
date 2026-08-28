module risc_v_tb;

reg clk, reset;
wire [1:0] imm_src;
wire result_src, memwrite, alu_src, regwrite, pc_src;
wire [31:0] pc, alu_result, wd, rd, inst;

risc_v RISC_v(clk,reset,result_src, memwrite, alu_src, regwrite, pc_src,imm_src,pc,inst,alu_result,wd,rd);
always #5 clk = ~clk;   

initial begin
clk = 0;
reset = 1;
#20 reset = 0;    
#20000;             
$stop;
end
initial begin
      
$display(" time   |   PC    |   INST   |  rd1   |  rd2   |  ALU  |  WD  |  RD  | RegW | MemW ");
$monitor("%t | %h | %h | %h | %h | %h | %h | %h |   %b   |   %b",$time, pc, inst,RISC_v.RF.rd1,RISC_v.RF.rd2, alu_result, wd, rd, regwrite, memwrite);

end
endmodule


