module error_status_reg (
    input  logic        clk,
    input  logic        reset,
    input  logic        single_err_in,
    input  logic        double_err_in,
    input  logic [31:0] addr_in,
    output logic        single_err_corrected,
    output logic        double_err_detected,
    output logic [31:0] error_addr
);
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            single_err_corrected <= 1'b0;
            double_err_detected  <= 1'b0;
            error_addr           <= '0;
        end
        else begin
            if (single_err_in) begin
                single_err_corrected <= 1'b1;
                error_addr           <= addr_in;
            end
            if (double_err_in) begin
                double_err_detected  <= 1'b1;
                error_addr           <= addr_in;
            end
        end
    end
endmodule
