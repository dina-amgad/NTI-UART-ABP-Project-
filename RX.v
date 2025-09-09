module uart_rx #(
    parameter DATAWIDTH = 8,
    parameter SB_TICK   = 16
) (
    input  clk,
    input  rx_rst,
    input  rx_en,
    input  rx,
    input  s_tick,
    output reg [DATAWIDTH-1:0] dout,
    output reg rx_done,
    output reg rx_busy,
    output reg rx_error
);

    localparam [1:0] IDLE  = 2'b00,
                     START = 2'b01,
                     DATA  = 2'b10,
                     STOP  = 2'b11;

    reg [1:0] state_reg, state_next;
    reg [DATAWIDTH-1:0] data_reg, data_next;
    reg [$clog2(DATAWIDTH)-1:0] n_reg, n_next;
    reg [$clog2(SB_TICK)-1:0] s_reg, s_next;

    always @(posedge clk or posedge rx_rst) begin
        if (rx_rst) begin
            state_reg <= IDLE;
            data_reg  <= 0;
            n_reg     <= 0;
            s_reg     <= 0;
            dout      <= 0;
            rx_done   <= 0;
            rx_busy   <= 0;
            rx_error  <= 0;
        end else begin
            state_reg <= state_next;
            data_reg  <= data_next;
            n_reg     <= n_next;
            s_reg     <= s_next;
            dout      <= data_reg;
        end
    end

    always @* begin
        state_next = state_reg;
        data_next  = data_reg;
        n_next     = n_reg;
        s_next     = s_reg;
        rx_done    = 1'b0;
        rx_busy    = (state_reg != IDLE);
        rx_error   = 1'b0; 

        if (rx_en) begin
            case (state_reg)
                IDLE: if (~rx) begin
                          state_next = START;
                          s_next     = 0;
                      end
                START: if (s_tick) begin
                           if (s_reg == 7) begin
                               state_next = DATA;
                               s_next     = 0;
                               n_next     = 0;
                           end else s_next = s_reg + 1;
                       end
                DATA: if (s_tick) begin
                          if (s_reg == 15) begin
                              data_next = {rx, data_reg[DATAWIDTH-1:1]};
                              s_next    = 0;
                              if (n_reg == (DATAWIDTH-1))
                                  state_next = STOP;
                              else
                                  n_next = n_reg + 1;
                          end else s_next = s_reg + 1;
                      end
                STOP: if (s_tick) begin
                          if (s_reg == (SB_TICK-1)) begin
                              if (~rx) rx_error = 1'b1; 
                              state_next = IDLE;
                              rx_done    = 1'b1;
                          end else s_next = s_reg + 1;
                      end
            endcase
        end
    end
endmodule
