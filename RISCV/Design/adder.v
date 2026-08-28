module adder(c,a,b);
input [31:0]a,b;
output [31:0]c;

assign c = a+b;

endmodule

module adder_tb();
reg [31:0]a,b;
wire [31:0]c;

adder ADD(c,a,b);

initial
begin

a=32'h0000000a; b=32'h00000004;
#5;
a=32'h0000001a; b=32'h00000034;
#5;
$stop;
end
initial begin 
$monitor("Time=%0t, a=%h, b=%h, c=%h", $time, a, b, c);
end

endmodule
