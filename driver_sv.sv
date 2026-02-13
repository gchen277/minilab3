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
    inout  logic  [7:0] io_databus
);

    logic [15:0] divisor;
    always_comb begin
        case (i_br_cfg)
            2'b11: divisor = 16'd1301;  // 38400
            2'b10: divisor = 16'd2603;  // 19200
            2'b01: divisor = 16'd5207;  // 9600
            2'b00: divisor = 16'd10415; // 4800
        endcase
    end

    logic [1:0] br_cfg_prev;
    logic baud_changed;

    always_ff @(posedge i_clk, negedge i_rst_n) begin 
        if (!i_rst_n) begin
            br_cfg_prev <= i_br_cfg; 
        end
        else
        br_cfg_prev <= i_br_cfg;
    end

    assign baud_changed = (i_br_cfg != br_cfg_prev);

    typedef enum {
        STATE_HI_BAUD,
        STATE_LOW_BAUD,
        STATE_IDLE,
        STATE_RX,
        STATE_AWAIT_TX,
        STATE_TX
    } state_t;
    state_t state;

    always_ff @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n) begin
            state <= STATE_LOW_BAUD;
        end
        else begin
            case (state)
            STATE_LOW_BAUD: begin
                state <= STATE_HI_BAUD;
            end
            STATE_HI_BAUD: begin
                state <= STATE_IDLE;
            end
            STATE_IDLE: begin
                if (baud_changed)
                    state <= STATE_LOW_BAUD;
                else if (i_rda)
                    state <= STATE_RX;
            end
            STATE_RX: begin
                state <= STATE_AWAIT_TX;
            end
            STATE_AWAIT_TX: begin
                if (baud_changed)
                    state <= STATE_LOW_BAUD;
                else if (i_tbr)
                    state <= STATE_TX;
            end
            STATE_TX: begin
                state <= STATE_IDLE;
            end
            endcase
        end
    end

    assign o_iocs = state == STATE_RX || state == STATE_TX || state == STATE_LOW_BAUD || state == STATE_HI_BAUD;
    assign o_iorw = state == STATE_RX;
    assign o_ioaddr = (state == STATE_LOW_BAUD) ? 2'b10 :
                      (state == STATE_HI_BAUD) ? 2'b11 : 2'b00;

    logic [7:0] databus_out;
    always_ff @(posedge i_clk) begin
        if (o_iorw) begin
            databus_out <= io_databus;
        end
    end
    wire [7:0] databus_drive_val;
    
    always_comb begin
        case (state)
            STATE_LOW_BAUD: databus_drive_val = divisor[7:0];
            STATE_HI_BAUD: databus_drive_val = divisor[15:8];
            STATE_TX:      databus_drive_val = databus_out;
            default:       databus_drive_val = 8'h00;
        endcase
    end
    assign io_databus = o_iorw ? 'Z : databus_drive_val;

endmodule

