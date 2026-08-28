module cu(alu_src,result_src,regwrite,memwrite,pc_src,imm_src,alu_control,opcode,fun3,fun7,zero);

input [6:0] opcode;
input zero,fun7;
input [2:0] fun3;
output [2:0] alu_control;
output [1:0] imm_src;
output result_src,memwrite,alu_src,regwrite,pc_src;
wire branch;
wire [1:0] aluop;

control_unit C1(branch, regwrite, memwrite, alu_src, result_src, imm_src, aluop, opcode);

alu_control C2(alu_control, aluop, fun3, fun7);
//assign pc_src = 1'b1;
assign pc_src = branch && zero;
endmodule

module cu_tb;

reg [6:0] opcode;
reg fun7,zero;
reg [2:0] fun3;

wire [2:0] alu_control;
wire [1:0] imm_src;
wire result_src, memwrite, alu_src, regwrite, pc_src;

cu CU(alu_src,result_src,regwrite,memwrite,pc_src,imm_src,alu_control,opcode,fun3,fun7,zero);

initial begin
    // R-type (add)
    opcode = 7'b0110011; fun7=1'b0; fun3=3'b000; zero=0;
    #10;

    // Load (lw)
    opcode = 7'b0000011; fun7=1'b0; fun3=3'b010; zero=0;
    #10;

    // Branch (BEQ, taken)
    opcode = 7'b1100011; fun3=3'b000; zero=1;
    #10;

    // Branch (BEQ, not taken)
    opcode = 7'b1100011; fun3=3'b000; zero=0;
    #10;
end

initial begin
    $monitor("time=%0t opcode=%b funct3=%b funct7=%b zero=%b | alu_control=%b pc_src=%b regwrite=%b memwrite=%b",$time, opcode, fun3, fun7, zero, alu_control, pc_src, regwrite, memwrite);
end
endmodule

