module control_unit(branch,regwrite,memwrite,alu_src,result_src,imm_src,aluop,opcode);
input [6:0]opcode;
output [1:0]aluop, imm_src;
output branch,regwrite,memwrite,alu_src,result_src;
wire [8:0]controls;

assign {alu_src,result_src,imm_src,regwrite,memwrite,branch,aluop} = controls;

assign controls = 
        (opcode == 7'b0110011) ? 9'b0_0_xx_1_0_0_10: // R-type
        (opcode == 7'b0000011) ? 9'b1_1_00_1_0_0_00: // Load (lw)
        (opcode == 7'b0100011) ? 9'b1_x_01_0_1_0_00: // Store (sw)
        (opcode == 7'b1100011) ? 9'b0_x_10_0_0_1_01: // Branch (beq/bne/blt/bge)
        (opcode == 7'b0010011) ? 9'b1_0_00_1_0_0_10: // I-type (addi)
                                 9'bx_x_xx_x_x_x_xx; // default
endmodule

module control_unit_tb;
reg [6:0] opcode;
wire branch, regwrite, memwrite, alu_src, result_src;
wire [1:0] imm_src, aluop;

control_unit C_UNIT(branch,regwrite,memwrite,alu_src,result_src,imm_src,aluop,opcode);
initial begin
opcode = 7'b0110011; // R-type
#10; 
opcode = 7'b0000011; // Load (lw)
#10; 
opcode = 7'b0100011; // Store (sw)
#10; 
opcode = 7'b1100011;  // Branch (beq/bne/bge)
#10;
opcode = 7'b0010011; // I-type (addi)
#10; 
opcode = 7'b1111111; // Default (invalid)
#10; 
end
initial begin 
$monitor("time=%0t opcode=%b | branch=%b regwrite=%b memwrite=%b alu_src=%b result_src=%b imm_src=%b aluop=%b",$time,
 opcode, branch, regwrite, memwrite, alu_src, result_src, imm_src, aluop);
end
endmodule
