//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    
// Design Name: 
// Module Name:    driver 
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
module driver(
    input clk,
    input rst,
    input [1:0] br_cfg,
    output iocs,
    output iorw,
    input rda,
    input tbr,
    output [1:0] ioaddr,
    inout [7:0] databus
    );

    driver_sv inst(
        .i_clk(clk),
        .i_rst(rst),
        .i_br_cfg(br_cfg),
        .o_iocs(iocs),
        .o_iorw(iorw),
        .i_rda(rda),
        .i_tbr(tbr),
        .o_ioaddr(ioaddr),
        .io_databus(databus)
    );

endmodule
