module risc_v(clk,reset,result_src, memwrite, alu_src, regwrite, pc_src,imm_src,pc,inst,alu_result,wd,rd);

input clk;
input reset;
output result_src, memwrite, alu_src, regwrite, pc_src;
output [1:0] imm_src;
output [31:0] pc;
output [31:0] inst;
output [31:0] alu_result;
output [31:0] wd;
output [31:0] rd;

wire [31:0] pc_next;                  
wire [31:0] pc_4;                      
wire [31:0] pc_target;                 
wire [31:0] rd1,rd2, result;          
wire [31:0] imm_ext;                   
wire [31:0] src_b;                     
wire [2:0] alu_control;                
wire [31:0] read_data;                 
wire zero;                             
wire clk_d;

clk_div clkd(clk,reset,clk_d);
             
mux PC_next(pc_next,pc_src,pc_4,pc_target);

pc ProgC(clk_d,reset,pc_next,pc);

adder pc_plus4(pc_4,pc,32'b100);

instr_mem IM(pc,inst);
 
reg_file RF(rd1,rd2,inst[19:15],inst[24:20],inst[11:7],result,regwrite,clk_d);

imm_ext ImmExt(imm_ext,imm_src,inst);

mux SRC_B(src_b,alu_src,rd2,imm_ext); 

alu ALU(alu_result,zero,rd1,src_b,alu_control);

//data_mem DM(read_data,clk_d,memwrite,alu_result,rd2);

//mux result_0(result,result_src,alu_result,read_data);

adder PC_target(pc_target,pc,imm_ext);

cu CU(alu_src,result_src,regwrite,memwrite,pc_src,imm_src,alu_control,inst[6:0],inst[14:12],inst[30],zero);

assign wd = rd2;         // write data to memory
assign rd = read_data;   // read data from memory

endmodule
