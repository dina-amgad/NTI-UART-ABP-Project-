`timescale 1ns/1ps

module apb_uart_tb;

    // Parameters
    localparam DATAWIDTH = 8;
    localparam CLK_PERIOD = 10; // 100 MHz

    // APB Signals
    reg  PCLK;
    reg  PRESETn;
    reg  PSEL;
    reg  PENABLE;
    reg  PWRITE;
    reg  [31:0] PADDR;
    reg  [31:0] PWDATA;
    wire [31:0] PRDATA;
    wire PREADY;

    // UART Signals
    reg  rx;
    wire tx;

    // Test variables
    reg [31:0] status;
    reg [31:0] tx_data;
    reg [31:0] rx_data;

    // Instantiate the DUT
    apb_uart #(
        .DATAWIDTH(DATAWIDTH),
        .CLK_FREQ(100_000_000)
    ) dut (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PADDR(PADDR),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .rx(rx),
        .tx(tx)
    );

    // Clock generation
    initial PCLK = 0;
    always #(CLK_PERIOD/2) PCLK = ~PCLK;

    // Reset generation
    initial begin
        PRESETn = 0;
        #50;
        PRESETn = 1;
    end

    // APB write task using negedge
    task apb_write(input [4:0] addr, input [31:0] data);
    begin
        @(negedge PCLK);        // Wait for falling edge (setup)
        PSEL    = 1;
        PENABLE = 0;
        PWRITE  = 1;
        PADDR   = addr;
        PWDATA  = data;

        @(negedge PCLK);        // Access phase (sample will occur on DUT's rising edge)
        PENABLE = 1;

        @(negedge PCLK);        // Transaction complete
        PSEL    = 0;
        PENABLE = 0;
    end
    endtask

    // APB read task using negedge
    task apb_read(input [4:0] addr, output [31:0] data);
    begin
        @(negedge PCLK);        // Setup phase
        PSEL    = 1;
        PENABLE = 0;
        PWRITE  = 0;
        PADDR   = addr;

        @(negedge PCLK);        // Access phase
        PENABLE = 1;

        @(negedge PCLK);        // Sample data
        data = PRDATA;

        PSEL    = 0;
        PENABLE = 0;
    end
    endtask

    // Test stimulus
    initial begin
        // Initialize signals
        PSEL    = 0;
        PENABLE = 0;
        PWRITE  = 0;
        PADDR   = 0;
        PWDATA  = 0;
        rx      = 1'b1; // Idle state

        @(negedge PRESETn);      // Wait for reset release

        // Enable UART TX/RX
        apb_write(5'h00, 4'b1111);  // tx_en, rx_en, tx_rst, rx_rst = 1

        // Load TX data
        apb_write(5'h02, 8'hA5);  // transmit 0xA5

        // Wait some time for transmission to finish
        #5000;

        // Read status register
        apb_read(5'h01, status);
        $display("Status Register: %h", status);

        // Read TX data register
        apb_read(5'h02, tx_data);
        $display("TX Data Register: %h", tx_data);

        // Read RX data register (assuming loopback for testing)
        apb_read(5'h03, rx_data);
        $display("RX Data Register: %h", rx_data);

        $stop;
    end

endmodule
