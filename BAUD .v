module baudrate_gen #(
    parameter BAUDRATE = 9600,
    parameter CLK_FREQ = 100_000_000
)(
    input clk,
    input reset,
    output reg tick
);

  
    localparam FINAL_TICK = (CLK_FREQ + (16*BAUDRATE - 1)) / (16*BAUDRATE);

    reg [15:0] counter;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tick    <= 0;
            counter <= 0;
        end else if (counter == (FINAL_TICK - 1)) begin
            counter <= 0;
            tick    <= 1;
        end else begin
            counter <= counter + 1;
            tick    <= 0;
        end
    end
endmodule




