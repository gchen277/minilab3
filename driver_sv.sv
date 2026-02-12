`default_nettype none

module driver_sv(
    input  logic i_clk,
    input  logic i_rst_n,

    /* Baud Rate */
    input  logic [1:0] i_br_cfg,

    output logic o_iocs,
    output logic o_iorw,
    input  logic i_rda,
    input  logic i_tbr,
    output logic [1:0] o_ioaddr,
    inout  wire  [7:0] io_databus
);

    typedef enum {
        STATE_IDLE,
        STATE_RX,
        STATE_AWAIT_TX,
        STATE_TX
    } state_t;
    state_t state;

    always_ff @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n) begin
            state <= STATE_IDLE;
        end
        else begin
            case (state) 
            STATE_IDLE: begin
                if (i_rda) begin
                    state <= STATE_RX;
                end
            end
            STATE_RX: begin
                state <= STATE_AWAIT_TX;
            end
            STATE_AWAIT_TX: begin
                if (i_tbr) begin
                    state <= STATE_TX;
                end
            end
            STATE_TX: begin
                state <= STATE_IDLE;
            end
            endcase
        end
    end

    assign o_iocs = state == STATE_RX || state == STATE_TX;
    assign o_iorw = state == STATE_RX;
    assign o_ioaddr = '0;

    logic [7:0] databus;
    always_ff @(posedge i_clk) begin
        if (o_iorw) begin
            databus <= io_databus;
        end
    end
    assign io_databus = o_iorw ? 'Z : databus;    

endmodule

