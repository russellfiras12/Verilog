`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:49:16 06/18/2018 
// Design Name: 
// Module Name:    uart_demo 
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
module uart_demo
#(parameter	DBIT = 8,		// # data bits
				SB_TICK = 16,	// # ticks for stop bits 16/24/32 for 1/1.5/2 bits
				DVSR = 108,		// DVSR = clk / (16*baudrate)
				DVSR_BIT = 8	// # bits for DVSR (log(108)/log(2))
)
(
	input wire clk, reset,
	input wire rx,
	output wire tx,
	input wire [7:0] tx_data,
	output wire [7:0] rx_data,
	
	input wire tx_start,
	output wire rx_done
);

wire baud_tick;
//wire rx_done;
//wire [7:0] rx_data;

mod_m_counter #(.M(DVSR), .N(DVSR_BIT)) baud_gen_unit
	(.clk(clk),
	.reset(reset),
	.q(),
	.max_tick(baud_tick));

uart_tx #(.DBIT(DBIT), .SB_TICK(SB_TICK)) uart_tx_unit
	(.clk(clk),
	.reset(reset),
	.tx_start(tx_start),
	.s_tick(baud_tick),
	.din(tx_data),
	.tx_done_tick(),
	.tx(tx));

uart_rx #(.DBIT(DBIT), .SB_TICK(SB_TICK)) uart_rx_unit
	(.clk(clk),
	.reset(reset),
	.rx(rx),
	.s_tick(baud_tick),
	.rx_done_tick(rx_done),
	.dout(rx_data));

endmodule
