`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:39:32 06/19/2018 
// Design Name: 
// Module Name:    spi_demo 
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
module spi_demo
(
	input wire clk,
	input wire reset,
	
	output wire mst_mosi,
	input wire mst_miso,
	output wire mst_spck,
	output wire mst_ncs,
	
	input wire slv_mosi,
	output wire slv_miso,
	input wire slv_spck,
	input wire slv_ncs,
	
	input wire tx_start,
	output wire rx_done,
	
	input wire [7:0] tx_data,
	output wire [7:0] rx_data
);

spi_slave spi_slave_unit
	(.clk(clk),
	.reset(reset),
	.spck(slv_spck),
	.ncs(slv_ncs),
	.mosi(slv_mosi),
	.miso(slv_miso),
	.thr(~tx_data),
	.rhr(rx_data),
	.rxrdy_tick());

spi_master spi_master_unit
	(.clk(clk),
	.reset(reset),
	.spck(mst_spck),
	.ncs(mst_ncs),
	.mosi(mst_mosi),
	.miso(mst_miso),
	.thr(tx_data),
	.rhr(),
	.start_tick(tx_start),
	.last_xfer(1'b1),
	.txrdy_tick(),
	.rxrdy_tick(),
	.done_tick(rx_done));

endmodule
