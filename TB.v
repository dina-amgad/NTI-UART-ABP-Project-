`timescale 1ns/1ps

module uart_tQb;

    localparam CLK_FREQ  = 100_000_000;
    localparam BAUDRATE  = 9600;
    localparam SB_TICK   = 16;
    localparam DATAWIDTH = 8;

    reg clk;
    reg reset;

    wire s_tick;
    wire tx;
    reg tx_start;
    reg tx_en, tx_rst;
    wire tx_done;
    wire tx_busy;
    reg [DATAWIDTH-1:0] tx_data;

    wire [DATAWIDTH-1:0] rx_data;
    reg rx_en, rx_rst;
    wire rx_done;
    wire rx_busy;
    wire rx_error;

    initial clk = 0;
    always #5 clk = ~clk;

    baudrate_gen #(.BAUDRATE(BAUDRATE), .CLK_FREQ(CLK_FREQ))
        baud (.clk(clk), .reset(reset), .tick(s_tick));

    uart_tx #(.DATAWIDTH(DATAWIDTH), .SB_TICK(SB_TICK)) 
        txu (
            .clk(clk), .tx_rst(tx_rst), .tx_en(tx_en),
            .tx_start(tx_start), .din(tx_data),
            .s_tick(s_tick), .tx(tx),
            .tx_done(tx_done), .tx_busy(tx_busy)
        );

    uart_rx #(.DATAWIDTH(DATAWIDTH), .SB_TICK(SB_TICK))
        rxu (
            .clk(clk), .rx_rst(rx_rst), .rx_en(rx_en),
            .rx(tx), .s_tick(s_tick),
            .dout(rx_data), .rx_done(rx_done),
            .rx_busy(rx_busy), .rx_error(rx_error)
        );

    initial begin
        reset    = 1;
        tx_rst   = 1;
        rx_rst   = 1;
        tx_en    = 0;
        rx_en    = 0;
        tx_data  = 0;
        tx_start = 0;
        #50 reset = 0;
        tx_rst   = 0;
        rx_rst   = 0;
        tx_en    = 1;
        rx_en    = 1;
        #1000;
        tx_data = 8'hC1;
        @(negedge clk) tx_start = 1;
        @(negedge clk) tx_start = 0;
        wait (rx_done);
        $display("TX sent: %02h", tx_data);
        $display("RX received: %02h | Error=%b", rx_data, rx_error);
        if (rx_data == 8'hC1 && !rx_error)
            $display("PASS: Successful Communication\n");
        else
            $display("FAIL: Expected Received Byte 0xC1\n");
        #2000 $finish;
    end
endmodule
