module sys_bus (
    input  logic        clk,
    input  logic        reset,
    input  logic        memwrite,
    input  logic [31:0] addr,
    input  logic [31:0] write_data,
    output logic [31:0] read_data,

    input  logic        fault_inject_en,
    input  logic [5:0]  fault_bit_pos,
    input  logic        fault_inject_en2,
    input  logic [5:0]  fault_bit_pos2,

    output logic        single_err_corrected,
    output logic        double_err_detected,
    output logic [31:0] error_addr,
    output logic [31:0] peripheral_reg_out
);
    logic ram_en, mmio_en;
    logic [31:0] ram_rd, mmio_rd;

    // Address decode: bit[31]=1 -> MMIO peripheral; bit[31]=0 -> RAM
    assign mmio_en = addr[31];
    assign ram_en  = ~addr[31];

    ecc_data_mem RAM (
        .clk                  (clk),
        .reset                (reset),
        .memwrite             (memwrite),
        .mem_sel              (ram_en),      //gates writes + error status
        .addr                 (addr),
        .wd                   (write_data),
        .rd                   (ram_rd),
        .fault_inject_en      (fault_inject_en),
        .fault_bit_pos        (fault_bit_pos),
        .fault_inject_en2     (fault_inject_en2),
        .fault_bit_pos2       (fault_bit_pos2),
        .single_err_corrected (single_err_corrected),
        .double_err_detected  (double_err_detected),
        .error_addr           (error_addr)
    );

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            peripheral_reg_out <= 32'h0;
        else if (memwrite && mmio_en)
            peripheral_reg_out <= write_data;
    end

    assign mmio_rd   = peripheral_reg_out;
    assign read_data = mmio_en ? mmio_rd : ram_rd;
endmodule

