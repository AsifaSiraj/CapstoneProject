module alu(result, zero, a, b, alu_control);

input  [31:0] a, b;
input  [2:0]  alu_control;   
output reg [31:0] result;
output reg zero;

always @(*) begin
    case (alu_control)
        3'd0: result = a + b;                          // ADD
        3'd1: result = a - b;                          // SUB
        3'd2: result = a & b;                          // AND
        3'd3: result = a | b;                          // OR
        3'd4: result = $signed(a) < $signed(b) ? 32'd1 : 32'd0; // SLT
        3'd5: result = a << b[4:0];                    // SLL
        3'd6: result = a >> b[4:0];                    // SRL
        3'd7: result = $signed(a) >>> b[4:0];          // SRA
        default: result = 32'h00000000;
    endcase
    
    // zero is 1 only when a == b (for BEQ)
    zero = (a == b);
end

endmodule

module alu_tb;

reg  [31:0] a, b;
reg  [3:0] alu_control;
wire [31:0] result;
wire zero;

alu ALU(result,zero,a,b,alu_control);

initial begin

a=10; b=5; alu_control=4'd0;//  ADD
#5
a=10; b=5; alu_control=4'd1;//SUB
#5        
a=10; b=5; alu_control=4'd2;//AND
#5
a=10; b=5; alu_control=4'd3;//OR
#5
a=10; b=5; alu_control=4'd4;//XOR
#5
a=-3; b=5; alu_control=4'd5;//SLT
#5
a=32'h0000_0001; b=3; alu_control=4'd6;//SLL
#5
a=32'h0000_0010; b=1; alu_control=4'd7;//SRL
#5
a=-32'd16; b=2; alu_control=4'd8;//SRA
#5
a=10; b=10; alu_control=4'd9;//BEQ
#5
a=10; b=20; alu_control=4'd10;//BNE
#5
a=20; b=10; alu_control=4'd11;//BGE
#5
a=-5; b=3; alu_control=4'd12;//BLT
#5;
end
initial begin
$monitor("time=%0t a=%0d b=%0d alu_control=%0d result=%0d zero=%b",$time, a, b, alu_control, result, zero);
end
endmodule
