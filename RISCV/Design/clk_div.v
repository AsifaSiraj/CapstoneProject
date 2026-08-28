module clk_div (clk,reset,clk_d);

input clk, reset;
output reg clk_d;
reg [31:0] count;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count   <= 0;
            clk_d <= 0;
        end else begin
            count <= count + 1;
            if (count == 99) begin  // small number for fast simulation
                clk_d <= ~clk_d;
                count   <= 0;
            end
        end
    end
endmodule

module clk_div_tb; 
reg clk, reset; 
wire clk_d; 

clk_div CLK (clk,reset,clk_d);

initial clk = 0; 
always #5 clk = ~clk;

initial begin 
reset = 1; 
#20 reset = 0; 
#2000 $stop;
end 

initial begin 
$monitor("t=%0t | clk=%b clk_d=%b", $time, clk, clk_d); 
end 
endmodule

