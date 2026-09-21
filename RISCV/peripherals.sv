`timescale 1ns/1ps
// ======================================================================
// peripherals.sv - Memory-mapped peripheral subsystem for the RISC-V SoC
//
//   0x8000_0000  TRACE        r/w  legacy trace register (peripheral_reg_out)
//   0x8000_0004  SPI_TXD      w    SPI transmit byte
//   0x8000_0008  SPI_CTRL     w    bit0=START, bit1=FREQ (1=fast 2clk/bit, 0=4clk/bit)
//   0x8000_000C  SPI_STAT     r    bit0=BUSY, bit1=DONE
//   0x8000_0010  SPI_RXD      r    SPI receive byte (loopback in TB)
// ======================================================================
module peripherals (
    input  logic        clk,
    input  logic        reset,

    // ---- bus side ----
    input  logic        memwrite,
    input  logic        mmio_en,        // addr[31] decode from sys_bus
    input  logic [31:0] addr,           // word addr[11:2] distinguishes registers
    input  logic [31:0] write_data,
    output logic [31:0] rd,

    // ---- physical I/O ----
    input  logic        spi_miso,       // SPI master input
    output logic        spi_sck,        // serial clock
    output logic        spi_mosi,       // serial out
    output logic        spi_cs,         // chip select (active low)

    // ---- status / observability ----
    output logic [31:0] peripheral_reg_out,
    output logic        spi_busy,

    // ---- observability for UVM verification (black-box checks) ----
    output logic [7:0]  spi_rx_out,
    output logic        spi_done_out
);
    // ---- register selects (word offsets within the MMIO space) ----
    wire [9:0] wo = addr[11:2];
    wire is_trace    = (wo == 10'h000);
    wire is_txd      = (wo == 10'h001);
    wire is_ctrl     = (wo == 10'h002);
    wire is_stat     = (wo == 10'h003);
    wire is_rxd      = (wo == 10'h004);

    wire wr      = memwrite && mmio_en;

    // ==================== register banks ====================
    logic [31:0] trace_reg;
    logic [31:0] spi_txd_reg;
   

    // ==================== SPI controller ====================
    localparam int SPICLK_SLOW = 4;
    localparam int SPICLK_FAST = 2;

    logic [3:0]  spi_pclk;
    logic [2:0]  spi_bit;
    logic        spi_sck_reg;
    logic        spi_mosi_reg;
    logic        spi_cs_reg;
    logic        spi_done;
    logic [7:0]  spi_shift;
    logic [7:0]  spi_rx_reg;
    logic        spi_start;
    logic [3:0]  clks_per_bit;
    logic        sample_edge;

    always_comb begin
        spi_start = 1'b0;
        if (wr && is_ctrl && write_data[0]) spi_start = 1'b1;
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            spi_busy     <= 1'b0;
            spi_done     <= 1'b0;
            spi_sck_reg  <= 1'b0;
            spi_cs_reg   <= 1'b1;
            spi_pclk     <= 4'd0;
            spi_bit      <= 3'd0;
            spi_rx_reg   <= 8'h00;
            spi_shift    <= 8'h00;
        end
        else if (spi_start) begin
            spi_busy     <= 1'b1;
            spi_done     <= 1'b0;
            spi_cs_reg   <= 1'b0;
            spi_pclk     <= 4'd0;
            spi_bit      <= 3'd0;
            spi_sck_reg  <= 1'b1;               // going-active edge
            spi_shift    <= spi_txd_reg;        // MSB-first: mosi = shift[7]
        end
        else if (spi_busy) begin
            spi_pclk <= spi_pclk + 4'd1;
            if (spi_pclk == sample_edge) begin
                spi_rx_reg        <= {spi_rx_reg[6:0], spi_miso};
                spi_sck_reg       <= 1'b1;      // rising: sample MISO
            end
            if (spi_pclk == (clks_per_bit - 4'd1)) begin
                spi_pclk   <= 4'd0;
                spi_sck_reg <= 1'b0;
                spi_shift  <= spi_shift << 1;   // advance to next bit
                if (spi_bit == 3'd7) begin
                    spi_busy   <= 1'b0;
                    spi_done   <= 1'b1;
                    spi_cs_reg <= 1'b1;
                end
                else begin
                    spi_bit <= spi_bit + 3'd1;
                end
            end
        end
    end

    logic spi_cfg_freq;
    assign clks_per_bit = spi_cfg_freq ? SPICLK_FAST : SPICLK_SLOW;
    always_comb begin
        if (spi_cfg_freq) sample_edge = 4'd1;   // fast: 2 clk/bit, sample at 1
        else              sample_edge = 4'd2;  // slow: 4 clk/bit, sample at 2
    end

    assign spi_sck  = spi_sck_reg;
    assign spi_mosi = spi_mosi_reg;
    assign spi_cs   = spi_cs_reg;
    assign spi_mosi_reg = spi_shift[7];   // MSB-first, stable for the whole bit

    // ==================== trace register + SPI config latch ====================
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            trace_reg      <= 32'h0;
            spi_txd_reg    <= 32'h0;
            spi_cfg_freq   <= 1'b0;
            pwm_period_reg <= 32'h0;
            pwm_duty_reg   <= 32'h0;
            pwm_en_reg     <= 32'h0;
            rpm_en_reg     <= 32'h0;
            wdt_en_reg     <= 32'h0;
            probe_wr       <= 32'h0;
        end
        else begin
            if (wr) begin
                case (wo)
                    10'h000: trace_reg      <= write_data;
                    10'h001: spi_txd_reg    <= write_data;
                    10'h002: spi_cfg_freq   <= write_data[1];
                    10'h005: pwm_period_reg <= write_data;
                    10'h006: pwm_duty_reg   <= write_data;
                    10'h007: pwm_en_reg     <= write_data;
                    10'h008: rpm_en_reg     <= write_data;
                    10'h00B: wdt_en_reg     <= write_data;
                    default: probe_wr       <= probe_wr;
                endcase
            end
        end
    end

    assign peripheral_reg_out = trace_reg;
    assign spi_rx_out        = spi_rx_reg;
    assign spi_done_out      = spi_done;

    // ==================== read mux ====================
    logic [31:0] stat_vec;
    always_comb begin
        case (wo)
            10'h000:                  rd = trace_reg;
            10'h003:                  rd = {30'b0, spi_done, spi_busy};
            10'h004:                  rd = {24'b0, spi_rx_reg};
        endcase
    end

endmodule