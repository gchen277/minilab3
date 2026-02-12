//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:   
// Design Name: 
// Module Name:    spart 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module spart(
    input clk,
    input rst_n,
    input iocs,
    input iorw,
    output rda,
    output tbr,
    input [1:0] ioaddr,
    inout [7:0] databus,
    output txd,
    input rxd
    );
    
    reg [7:0] db_out;
    wire db_drive = iocs && iorw;      // only drive during reads
    assign databus = db_drive ? db_out : 8'hZZ;
    wire [7:0] db_in = databus;

    wire bus_wr = iocs && ~iorw;
    wire bus_rd = iocs &&  iorw;

    reg [7:0] rx_buf;
    reg       rx_full;   // RDA flag

    reg [7:0] tx_buf;
    reg       tx_full;   // buffer occupied (inverse of TBR)

    assign rda = rx_full;
    assign tbr = ~tx_full;

    // Read mux: 00=RXBUF, 01=STATUS. (10/11 unused now)
    always @(*) begin
     case (ioaddr)
            2'b00: db_out = rx_buf;
            default: db_out = 8'h00;
        endcase
    end

    localparam [15:0] DIV = 16'd1280;
    reg  [15:0] brg_cnt;
    reg  enable_pulse;
    always @(posedge clk) begin
        if (!rst_n) begin
            brg_cnt <= DIV;
            enable_pulse <= 1'b0;
        end else begin
            enable_pulse <= 1'b0;
            if (brg_cnt == 16'd0) begin
                brg_cnt <= DIV;
                enable_pulse <= 1'b1;
            end else begin
                brg_cnt <= brg_cnt - 16'd1;
            end
        end
    end



localparam TX_IDLE  = 2'd0;
localparam TX_START = 2'd1;
localparam TX_DATA  = 2'd2;
localparam TX_STOP  = 2'd3;

    reg [1:0]  tx_state;
    reg [2:0] tx_bitcnt;
    always @(posedge clk) begin
        if (!rst_n) begin
            tx_state  <= TX_IDLE;
            tx_buf    <= 8'h00;
            tx_full   <= 1'b0;
            tx_bitcnt <= 3'd0;
        end else begin
            case (tx_state)
                TX_IDLE: begin
                    if (bus_wr && (ioaddr == 2'b00) && tbr) begin
                        tx_buf    <= db_in;
                        tx_full   <= 1'b1;
                        tx_bitcnt <= 3'd0;      // start counting bits
                        tx_state  <= TX_START;
                    end
                end
                TX_START: begin
                    if (enable_pulse) begin
                        tx_state <= TX_DATA;
                    end
                end
                TX_DATA: begin
                    if (enable_pulse) begin
                        if (tx_bitcnt == 3'd7) begin
                            tx_state <= TX_STOP;           // after 8 bits, go to stop
                        end else begin
                            tx_bitcnt <= tx_bitcnt + 3'd1; // next bit
                        end
                        tx_buf <= {1'b0, tx_buf[7:1]};     // shift right, LSB first
                    end
                end
                TX_STOP: begin
                    if (enable_pulse) begin
                        tx_full <= 1'b0; // transmission done, buffer empty
                        tx_state <= TX_IDLE;
                    end
                end
            endcase
        end
    end
    assign txd = (tx_state == TX_IDLE) ? 1'b1 : tx_buf[0]; // idle high, data on LSB


localparam RX_IDLE  = 2'd0;
localparam RX_START = 2'd1;
localparam RX_DATA  = 2'd2;
localparam RX_STOP  = 2'd3;

    reg [1:0]  rx_state;
    reg [2:0] rx_bitcnt;


    always @(posedge clk) begin
        if (!rst_n) begin
            rx_state  <= RX_IDLE;
            rx_buf    <= 8'h00;
            rx_full   <= 1'b0;
            rx_bitcnt <= 3'd0;
        end else begin
            case (rx_state)

                RX_IDLE: begin
                    if (rxd == 1'b0) begin // start bit detected
                        rx_state  <= RX_START;
                    end
                end

                RX_START: begin
                    if (enable_pulse) begin
                        if (rxd == 1'b0) begin
                            rx_state  <= RX_DATA;
                            rx_bitcnt <= 3'd0;   // reset counter
                        end else begin
                            rx_state <= RX_IDLE;
                        end
                    end
                end
                RX_DATA: begin
                    if (enable_pulse) begin
                        rx_buf <= {rxd, rx_buf[7:1]};

                        if (rx_bitcnt == 3'd7) begin
                            rx_state <= RX_STOP;   // 8 bits received
                        end else begin
                            rx_bitcnt <= rx_bitcnt + 3'd1;
                        end
                    end
                end

                RX_STOP: begin
                    if (enable_pulse) begin
                        if (rxd == 1'b1) begin
                            rx_full <= 1'b1;
                        end
                        rx_state <= RX_IDLE;
                    end
                end
            endcase

            if (bus_rd && ioaddr == 2'b00) begin
                rx_full <= 1'b0;
            end
        end
    end

endmodule