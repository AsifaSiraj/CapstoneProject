module pc(clk,reset,x,out);
input clk,reset;
input [31:0]x;
output reg [31:0]out;

initial
out=0;

always @(posedge clk)
begin 
 if (reset)
 out <= 32'd0;
 else 
 out <= x;
end
endmodule

module pc_tb;

reg clk, reset;
wire [31:0] x;  
wire [31:0] out;

pc PC(clk, reset, x, out);

adder ADD1(x, out, 32'd4);

initial clk = 0;
always #5 clk = ~clk;   

initial begin
    reset = 1;   
    #10 reset = 0; 
    #50 reset = 1; 
    #10 reset = 0;  
    #30;
    $stop;
end

// Monitor values
initial
    $monitor("time=%0t, reset=%b, out=%h, x=%h", $time, reset, out, x);

endmodule

