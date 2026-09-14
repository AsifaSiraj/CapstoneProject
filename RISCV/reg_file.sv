module reg_file (
    output logic [31:0] rd1,
    output logic [31:0] rd2,
    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,
    input  logic [4:0]  rd,
    input  logic [31:0] wd,
    input  logic        regwrite,
    input  logic        clk,
    input  logic        reset
);
    logic [31:0] regs [0:31];

    assign rd1 = (rs1 == 5'd0) ? 32'd0 : regs[rs1];
    assign rd2 = (rs2 == 5'd0) ? 32'd0 : regs[rs2];

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (int i = 0; i < 32; i++)
                regs[i] <= 32'd0;
        end else if (regwrite && (rd != 5'd0)) begin
            regs[rd] <= wd;
        end
    end
endmodule
