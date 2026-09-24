`timescale 1ns/1ps
// ======================================================================
// peripherals.sv - Memory-mapped peripheral subsystem for the RISC-V SoC
//
//   0x8000_0000  TRACE        r/w  legacy trace register (peripheral_reg_out)
//   0x8000_0004  SPI_TXD      w    SPI transmit byte
//   0x8000_0008  SPI_CTRL     w    bit0=START, bit1=FREQ (1=fast 2clk/bit, 0=4clk/bit)
//   0x8000_000C  SPI_STAT     r    bit0=BUSY, bit1=DONE
//   0x8000_0010  SPI_RXD      r    SPI receive byte (loopback in TB)
//   0x8000_0014  PWM_PERIOD   w    PWM period in clock cycles
//   0x8000_0018  PWM_DUTY     w    PWM high duty in clock cycles
//   0x8000_001C  PWM_CTRL     w    bit0=EN
//   0x8000_0020  RPM_CTRL     w    bit0=EN
//   0x8000_0024  RPM_PERIOD   r    measured tach edge-to-edge period (cycles)
//   0x8000_0028  RPM_STAT     r    bit0=VALID
//   0x8000_002C  PROFILE_CTRL w    bit0=LOAD
//   0x8000_0030..4C PROFILE[7:0] w profile payload entries
//   0x8000_0050  PROFILE_STAT r    bit0=LOADED, bit1=ACTIVE
//   0x8000_0054  FS_CTRL      w    bit0=WDT_EN (watchdog enable)
//   0x8000_0058  FS_STAT      r    bit0=FAIL_SAFE, bit1=WDT_TIMEOUT
//
// Fail-safe behaviour (FAIL_SAFE latches until reset):
//   -> triggers on uncorrectable ECC double-bit error (double_err_detected)
//   -> triggers on watchdog timeout (no tach edge within 256 cycles of WDT_EN)
//   -> while FAIL_SAFE is latched, PWM output is forced off.
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

    // ---- ECC fail-safe coupling ----
    input  logic        double_err_detected,

    // ---- physical I/O ----
    input  logic        tach_in,        // rotation sensor, pulsing input (RPM)
    input  logic        spi_miso,       // SPI master input
    output logic        spi_sck,        // serial clock
    output logic        spi_mosi,       // serial out
    output logic        spi_cs,         // chip select (active low)
    output logic        pwm_out,        // pulse-width-modulated output

    // ---- status / observability ----
    output logic [31:0] peripheral_reg_out,
    output logic        spi_busy,
    output logic        stall,          // core access to busy peripheral (stall request)
    output logic        fail_safe_active,

    // ---- observability for UVM verification (black-box checks) ----
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
    // ---- register selects (word offsets within the MMIO space) ----
    wire [9:0] wo = addr[11:2];
    wire is_trace    = (wo == 10'h000);
    wire is_txd      = (wo == 10'h001);
    wire is_ctrl     = (wo == 10'h002);
    wire is_stat     = (wo == 10'h003);
    wire is_rxd      = (wo == 10'h004);
    wire is_pperiod  = (wo == 10'h005);
    wire is_pduty    = (wo == 10'h006);
    wire is_pctrl    = (wo == 10'h007);
    wire is_rctrl    = (wo == 10'h008);
    wire is_rperiod  = (wo == 10'h009);
    wire is_rstat    = (wo == 10'h00A);
    wire is_fctrl    = (wo == 10'h00B);
    wire is_prc      = mmio_en && (wo >= 10'h00C) && (wo <= 10'h013); // 0x30..0x4C
    wire is_prstat   = (wo == 10'h014);
    wire is_fsc      = (wo == 10'h015);
    wire is_fsstat   = (wo == 10'h016);

    wire wr      = memwrite && mmio_en;
    wire [3:0] pr_index = wo[3:0] - 4'hC;   // 0..7 for profile entries

    // ==================== register banks ====================
    logic [31:0] trace_reg;
    logic [31:0] spi_txd_reg;
    logic [31:0] pwm_period_reg;
    logic [31:0] pwm_duty_reg;
    logic [31:0] pwm_en_reg;
    logic [31:0] rpm_en_reg;
    logic [31:0] wdt_en_reg;
    logic [31:0] profile_mem [0:7];
    logic [31:0] profile_loaded_reg;
    logic [31:0] profile_active_reg;
    logic [31:0] probe_wr;

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

    // ==================== PWM generator ====================
    logic [15:0] pwm_cnt;
    logic        pwm_internal;

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            pwm_cnt <= 16'd0;
        else if (pwm_en_reg[0] && !fail_safe_active && (pwm_period_reg[15:0] != 16'd0)) begin
            if (pwm_cnt >= (pwm_period_reg[15:0] - 16'd1))
                pwm_cnt <= 16'd0;
            else
                pwm_cnt <= pwm_cnt + 16'd1;
        end
        else if (!pwm_en_reg[0] || fail_safe_active)
            pwm_cnt <= 16'd0;
    end

    always_comb begin
        pwm_internal = 1'b0;
        if (pwm_en_reg[0] && !fail_safe_active &&
            (pwm_period_reg[15:0] != 16'd0) && (pwm_cnt < pwm_duty_reg[15:0]))
            pwm_internal = 1'b1;
    end

    assign pwm_out = (fail_safe_active) ? 1'b0 : pwm_internal;

    // ==================== RPM measurement ====================
    logic [31:0] rpm_cnt;
    logic [31:0] rpm_period_reg;
    logic        rpm_valid_reg;
    logic        tach_d1;
    logic        tach_rise;

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            tach_d1 <= 1'b0;
        else
            tach_d1 <= tach_in;
    end
    assign tach_rise = tach_in && !tach_d1;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            rpm_cnt        <= 32'd0;
            rpm_period_reg <= 32'd0;
            rpm_valid_reg  <= 1'b0;
        end
        else if (rpm_en_reg[0] && tach_rise) begin
            // inclusive count: clock cycles between consecutive rising edges
            rpm_period_reg <= rpm_cnt + 32'd1;
            rpm_valid_reg  <= 1'b1;
            rpm_cnt        <= 32'd0;
        end
        else if (rpm_en_reg[0]) begin
            rpm_cnt <= rpm_cnt + 32'd1;
        end
        else begin
            rpm_cnt <= 32'd0;
        end
    end

    // ==================== profile loading ====================
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (int i = 0; i < 8; i++) profile_mem[i] <= 32'h0;
            profile_loaded_reg <= 32'h0;
            profile_active_reg <= 32'h0;
        end
        else begin
            if (wr && is_prc)
                profile_mem[pr_index] <= write_data;
            if (wr && is_fctrl && write_data[0]) begin
                profile_loaded_reg <= 32'h1;
                profile_active_reg <= 32'h1;
            end
        end
    end

    // ==================== watch-dog / fail-safe ====================
    logic [7:0]  wdt_cnt;
    logic        wdt_timeout_reg;
    logic        fail_safe_reg;
    logic        wdt_en_reg_i;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            wdt_en_reg_i   <= 1'b0;
            wdt_cnt        <= 8'd0;
            wdt_timeout_reg <= 1'b0;
            fail_safe_reg  <= 1'b0;
        end
        else begin
            // latch fail-safe trigger inputs
            if (double_err_detected) fail_safe_reg <= 1'b1;
            if (wr && is_fsc && write_data[0]) begin
                wdt_en_reg_i <= 1'b1;
                wdt_cnt      <= 8'd0;
                wdt_timeout_reg <= 1'b0;
            end
            if (wdt_en_reg_i && !wdt_timeout_reg) begin
                if (tach_rise)
                    wdt_cnt <= 8'd0;
                else if (wdt_cnt == 8'hFF) begin
                    wdt_timeout_reg <= 1'b1;
                    fail_safe_reg   <= 1'b1;
                end
                else
                    wdt_cnt <= wdt_cnt + 8'd1;
            end
        end
    end

    assign fail_safe_active = fail_safe_reg;

    // ==================== stall detection ====================
    wire spi_block  = mmio_en && (wo >= 10'h001) && (wo <= 10'h004);
    wire is_nonstart = !(wr && is_ctrl);                 // START write itself isn't a stall
    assign stall = spi_block && spi_busy && is_nonstart;

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
    assign pwm_period_out    = pwm_period_reg[15:0];
    assign pwm_duty_out      = pwm_duty_reg[15:0];
    assign rpm_period_out    = rpm_period_reg;
    assign rpm_valid_out     = rpm_valid_reg;
    assign profile_loaded_out = profile_loaded_reg[0];
    assign profile_active_out = profile_active_reg[0];
    assign wdt_timeout_out   = wdt_timeout_reg;

    // ==================== read mux ====================
    logic [31:0] stat_vec;
    always_comb begin
        case (wo)
            10'h000:                  rd = trace_reg;
            10'h003:                  rd = {30'b0, spi_done, spi_busy};
            10'h004:                  rd = {24'b0, spi_rx_reg};
            10'h009:                  rd = rpm_period_reg;
            10'h00A:                  rd = {31'b0, rpm_valid_reg};
            10'h014:                  rd = {30'b0, profile_active_reg[0], profile_loaded_reg[0]};
            10'h016:                  rd = {30'b0, wdt_timeout_reg, fail_safe_reg};
            default:                  rd = 32'h0;
        endcase
    end

endmodule