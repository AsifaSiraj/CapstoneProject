module imm_ext(imm_out,imm_src,inst);
input [1:0]imm_src;
input [31:0]inst;
output reg [31:0]imm_out;

always @(*) begin
    case (imm_src)
        2'b00: begin
            imm_out = {{20{inst[31]}}, inst[31:20]}; // I-Type
        end
        
        2'b01: begin
            imm_out = {{20{inst[31]}}, inst[31:25], inst[11:7]}; //S-Type
        end
        
        2'b10: begin
          imm_out = {{20{inst[31]}},inst[7],inst[30:25], inst[11:8], 1'b0}; //B-Type
        end

        2'b11: begin
          imm_out = {{12{inst[31]}},inst[19:12], inst[20], inst[30:21], 1'b0}; //J-Type
        end
        
        default: imm_out = 32'b0;
    endcase
end

endmodule
 
module imm_ext_tb;

reg [31:0] inst;
reg [1:0]  imm_src;
wire [31:0] imm_out;

imm_ext IMM_EXT(imm_out,imm_src,inst);

initial begin

//addi x5, x0, 10
inst = 32'h00A00293;  
imm_src = 2'b00;     
#10
//sw x6, 8(x5)
inst = 32'h0062A423;  
imm_src = 2'b01;      
#10
//beq x5, x4, 
inst = 32'h0042A063;  
imm_src = 2'b10;      
#15
//add x7, x6, x5 
inst = 32'h005303B3;  
imm_src = 2'b11;      
#10;
// beq x4, x5, -20
inst = 32'hfe521ae3; 
imm_src = 2'b10;
#10;
end
initial begin
$monitor("time=%0t inst=%h imm_src=%b imm_out=%h",$time, inst, imm_src, imm_out);
end
endmodule

