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
    output logic [31:0] peripheral_reg_out,

    // ---- peripheral I/O ----
    input  logic        tach_in,
    input  logic        spi_miso,
    output logic        spi_sck,
    output logic        spi_mosi,
    output logic        spi_cs,
    output logic        pwm_out,
    output logic        spi_busy,
    output logic        stall,
    output logic        fail_safe_active,

    // ---- observability (UVM black-box checks) ----
    output logic [7:0]  spi_rx_out,
    output logic        spi_done_out,
    output logic [15:0] pwm_period_out,
    output logic [15:0] pwm_duty_out,
    output logic [31:0] rpm_period_out,
    output logic        rpm_valid_out,
    output logic        profile_loaded_out,
    output logic        profile_active_out,
    output logic        wdt_timeout_out
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

    peripherals PERIPH (
        .clk                  (clk),
        .reset                (reset),
        .memwrite             (memwrite),
        .mmio_en              (mmio_en),
        .addr                 (addr),
        .write_data           (write_data),
        .rd                   (mmio_rd),
        .double_err_detected  (double_err_detected),
        .tach_in              (tach_in),
        .spi_miso             (spi_miso),
        .spi_sck              (spi_sck),
        .spi_mosi             (spi_mosi),
        .spi_cs               (spi_cs),
        .pwm_out              (pwm_out),
        .peripheral_reg_out   (peripheral_reg_out),
        .spi_busy             (spi_busy),
        .stall                (stall),
        .fail_safe_active     (fail_safe_active),
        .spi_rx_out           (spi_rx_out),
        .spi_done_out         (spi_done_out),
        .pwm_period_out       (pwm_period_out),
        .pwm_duty_out         (pwm_duty_out),
        .rpm_period_out       (rpm_period_out),
        .rpm_valid_out        (rpm_valid_out),
        .profile_loaded_out   (profile_loaded_out),
        .profile_active_out   (profile_active_out),
        .wdt_timeout_out      (wdt_timeout_out)
    );

    assign read_data = mmio_en ? mmio_rd : ram_rd;
endmodule