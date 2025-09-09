module apb_uart #(
    parameter DATAWIDTH = 8,
    parameter CLK_FREQ  = 100_000_000
)(
    input  wire        PCLK,
    input  wire        PRESETn,
    input  wire [31:0] PADDR,
    input  wire        PSEL,
    input  wire        PENABLE,
    input  wire        PWRITE,
    input  wire [31:0] PWDATA,
    output reg  [31:0] PRDATA,
    output reg         PREADY,
    input  wire        rx,
    output wire        tx
);

    reg        tx_en, rx_en;
    reg        tx_rst, rx_rst;
    reg [DATAWIDTH-1:0] tx_data_reg;
    wire [DATAWIDTH-1:0] rx_data_wire;
    wire tx_done, tx_busy;
    wire rx_done, rx_busy, rx_error;
    reg [31:0] bauddiv_reg;
    reg tx_start_pulse;

    wire s_tick;
    baudrate_gen #(
        .BAUDRATE (9600),
        .CLK_FREQ (CLK_FREQ)
    ) baud_inst (
        .clk    (PCLK),
        .reset  (~PRESETn),
        .tick   (s_tick)
    );

    uart_tx #(
        .DATAWIDTH(DATAWIDTH)
    ) tx_inst (
        .clk      (PCLK),
        .tx_rst   (tx_rst),
        .tx_en    (tx_en),
        .tx_start (tx_start_pulse),
        .din      (tx_data_reg),
        .s_tick   (s_tick),
        .tx       (tx),
        .tx_done  (tx_done),
        .tx_busy  (tx_busy)
    );

    uart_rx #(
        .DATAWIDTH(DATAWIDTH)
    ) rx_inst (
        .clk     (PCLK),
        .rx_rst  (rx_rst),
        .rx_en   (rx_en),
        .rx      (rx),
        .s_tick  (s_tick),
        .dout    (rx_data_wire),
        .rx_done (rx_done),
        .rx_busy (rx_busy),
        .rx_error(rx_error)
    );

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            {tx_en, rx_en, tx_rst, rx_rst} <= 4'b0;
            tx_data_reg    <= 0;
            bauddiv_reg    <= 0;
            tx_start_pulse <= 0;
            PREADY         <= 0;
            PRDATA         <= 0;
        end else begin
            PREADY         <= 0;
            tx_start_pulse <= 0;
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[4:0])
                        5'h00: {tx_en, rx_en, tx_rst, rx_rst} <= PWDATA[3:0];
                        5'h02: begin
                            tx_data_reg    <= PWDATA[DATAWIDTH-1:0];
                            tx_start_pulse <= 1'b1;
                        end
                        5'h04: bauddiv_reg <= PWDATA;
                    endcase
                end else begin
                    case (PADDR[4:0])
                        5'h00: PRDATA <= {28'b0, tx_en, rx_en, tx_rst, rx_rst};
                        5'h01: PRDATA <= {27'b0, rx_error, tx_done, rx_done, tx_busy, rx_busy};
                        5'h02: PRDATA <= {24'b0, tx_data_reg};
                        5'h03: PRDATA <= {24'b0, rx_data_wire};
                        5'h04: PRDATA <= bauddiv_reg;
                        default: PRDATA <= 32'b0;
                    endcase
                end
            end
        end
    end

endmodule
