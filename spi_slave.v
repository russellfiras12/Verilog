`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:36:12 06/19/2018 
// Design Name: 
// Module Name:    spi_slave 
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
module spi_slave
(
	input wire clk,
	input wire reset,
	input wire spck,			// serial clock
	input wire ncs,			// (not) chip select
	input wire mosi,			// master out slave in
	output wire miso,			// master in slave out
	input wire [7:0] thr,	// data to transmit
	output wire [7:0] rhr,	// data received
	output reg rxrdy_tick	// end of reception
);

localparam [1:0]
	idle = 2'b00,
	load = 2'b01,
	data = 2'b11;

reg [1:0] state_reg, state_next;
reg [2:0] n_reg, n_next;

reg [7:0] tx_reg, tx_next;
reg [7:0] rx_reg, rx_next;

wire spck_re, spck_fe;

edge_detector #(.N(5)) spck_edge_unit
	(.clk(clk),
	.reset(reset),
	.signal(spck),
	.rising_edge(spck_re),
	.falling_edge(spck_fe));
	
always @(posedge clk, posedge reset)
begin
	if(reset)
		begin
			state_reg <= idle;
			n_reg <= 0;
			tx_reg <= 0;
			rx_reg <= 0;
		end
	else
		begin
			state_reg <= state_next;
			n_reg <= n_next;
			tx_reg <= tx_next;
			rx_reg <= rx_next;
		end
end

always @*
begin
	state_next = state_reg;
	n_next = n_reg;
	tx_next = tx_reg;
	rx_next = rx_reg;
	
	rxrdy_tick = 1'b0;
	
	case(state_reg)
		idle:
			begin
				if(~ncs)
					begin
						state_next = load;
					end
			end
		load:
			begin
				// if the NCS line is deasserted, return to idle state
				if(ncs)
					begin
						state_next = idle;
					end
				else
					begin
						tx_next = thr;
						state_next = data;
						n_next = 0;
					end
			end
		data:
			begin
				// if the NCS line is deasserted, return to idle state
				if(ncs)
					begin
						state_next = idle;
					end
				else
					begin
						// Shift data on the falling edge
						if(spck_fe)
							begin
								tx_next = tx_reg << 1;
								if(n_reg == 7)
									begin
										// Return to load for the next byte
										state_next = load;
										n_next = 0;
									end
								else
									begin
										n_next = n_reg + 1'b1;
									end
							end
						
						// Read data on the rising edge
						if(spck_re)
							begin
								rx_next = {rx_reg[6:0], mosi};
								if(n_reg == 7)
									begin
										rxrdy_tick = 1'b1;
									end
							end
					end
			end
	endcase
end

assign miso = tx_reg[7];
assign rhr = rx_reg;

endmodule
