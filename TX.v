module uart_tx #(
    parameter DATAWIDTH = 8,
    parameter SB_TICK   = 16
)(
    input  clk,
    input  tx_rst,
    input  tx_en,
    input  tx_start,
    input  [DATAWIDTH-1:0] din,
    input  s_tick,
    output reg tx,
    output reg tx_done,
    output reg tx_busy
);

    localparam [1:0] IDLE  = 2'b00,
                     START = 2'b01,
                     DATA  = 2'b10,
                     STOP  = 2'b11;

    reg [1:0] state, state_n;
    reg [$clog2(SB_TICK)-1:0] s_reg, s_n;
    reg [$clog2(DATAWIDTH)-1:0] n_reg, n_n;
    reg [DATAWIDTH-1:0] b_reg, b_n;
    reg tx_n, tx_done_n;

    always @(posedge clk or posedge tx_rst) begin
        if (tx_rst) begin
            state    <= IDLE;
            s_reg    <= 0;
            n_reg    <= 0;
            b_reg    <= 0;
            tx       <= 1'b1;
            tx_done  <= 1'b0;
            tx_busy  <= 1'b0;
        end else begin
            state    <= state_n;
            s_reg    <= s_n;
            n_reg    <= n_n;
            b_reg    <= b_n;
            tx       <= tx_n;
            tx_done  <= tx_done_n;
            tx_busy  <= (state_n != IDLE);
        end
    end

    always @* begin
        state_n    = state;
        s_n        = s_reg;
        n_n        = n_reg;
        b_n        = b_reg;
        tx_n       = tx;
        tx_done_n  = 1'b0;

        if (tx_en) begin
            case (state)
                IDLE: begin
                    tx_n = 1'b1;
                    if (tx_start) begin
                        b_n     = din;
                        s_n     = 0;
                        state_n = START;
                    end
                end
                START: begin
                    tx_n = 1'b0;
                    if (s_tick) begin
                        if (s_reg == SB_TICK-1) begin
                            s_n     = 0;
                            n_n     = 0;
                            state_n = DATA;
                        end else s_n = s_reg + 1;
                    end
                end
                DATA: begin
                    tx_n = b_reg[n_reg];
                    if (s_tick) begin
                        if (s_reg == SB_TICK-1) begin
                            s_n = 0;
                            if (n_reg == DATAWIDTH-1)
                                state_n = STOP;
                            else
                                n_n = n_reg + 1;
                        end else s_n = s_reg + 1;
                    end
                end
                STOP: begin
                    tx_n = 1'b1;
                    if (s_tick) begin
                        if (s_reg == SB_TICK-1) begin
                            state_n   = IDLE;
                            tx_done_n = 1'b1;
                            s_n       = 0;
                        end else s_n = s_reg + 1;
                    end
                end
            endcase
        end
    end
endmodule
