module mux(y,sel,a,b);
input sel;
input [31:0]a,b;
output reg [31:0]y;
always@(*)
if (sel)
y=b;
else
y=a;
endmodule

module mux_tb;

reg [31:0]a,b;
reg sel;
wire [31:0]y;

mux MUX(y,sel,a,b);

initial begin
a=32'h3452ADC2;
b=32'hABE4789F;
sel=1'b0;
#10;
sel=1'b1;
#10;
end

initial
  $monitor("time=%0t,sel=%b,a=%h,b=%h,y=%h",$time,sel,a,b,y);
endmodule