`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:46:32 06/19/2018 
// Design Name: 
// Module Name:    spi_master 
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
module spi_master
(
	input wire clk,
	input wire reset,
	output wire spck,
	output reg ncs,
	output wire mosi,
	input wire miso,
	input wire [7:0] thr,
	output wire [7:0] rhr,
	input wire start_tick,
	input wire last_xfer,
	output reg txrdy_tick,
	output reg rxrdy_tick,
	output reg done_tick
);

localparam [1:0]
	idle	= 2'b00,
	start = 2'b01,
	data	= 2'b11,
	stop	= 2'b10;
	
reg [1:0] state_reg, state_next;
reg [2:0] n_reg, n_next;
reg [7:0] tx_reg, tx_next;
reg [7:0] rx_reg, rx_next;

// peripheral clock controller
reg q_reg, q_next = 0;				// clock latch
reg [11:0] count_reg, count_next;	// master clock divider
wire sclk;								// peripheral clock
wire sclk_re, sclk_fe;				// edge detect

edge_detector #(.N(5)) sclk_edge_unit
	(.clk(clk),
	.reset(reset),
	.signal(sclk),
	.rising_edge(sclk_re),
	.falling_edge(sclk_fe));
	
always @(posedge clk, posedge reset)
begin
	if(reset)
		begin
			count_reg <= 0;
			q_reg <= 0;
		end
	else
		begin
			count_reg <= count_next;
			q_reg <= q_next;
		end
end

always @*
begin
	count_next = count_reg + 1'b1;
	q_next = q_reg;
	if(count_reg == 2000)
		begin
			count_next = 0;
			q_next = ~q_reg;
		end
end

assign sclk = q_reg;

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
	
	ncs = 1'b1;
	txrdy_tick = 1'b0;
	rxrdy_tick = 1'b0;
	done_tick = 1'b0;
	
	case(state_reg)
		idle:
			begin
				if(start_tick)
					begin
						state_next = start;
						n_next = 0;
					end
			end
		start:
			begin
				ncs = 1'b0;
				// wait for the 1st rising edge
				if(n_reg == 0)
					begin
						if(sclk_re)
							begin
								n_next = n_reg + 1'b1;
							end
					end
				// then wait for the 1st falling edge
				if(n_reg == 1)
					begin
						if(sclk_fe)
							begin
								n_next = 0;
								tx_next = thr;
								txrdy_tick = 1'b1;	// signal that the transmit data has been loaded to the transmit register
								state_next = data;
							end
					end
			end
		data:
			begin
				ncs = 1'b0;
				
				// shift data on the falling edge
				if(sclk_fe)
					begin
						tx_next = tx_reg << 1;
						if(n_reg == 7)
							begin
								rxrdy_tick = 1'b1;
								n_next = 0;
								if(last_xfer)
									begin
										state_next = stop;
									end
								else
									begin
										tx_next = thr;
										txrdy_tick = 1'b1;
									end
							end
						else
							begin
								n_next = n_reg + 1'b1;
							end
					end
					
				
				// read data on the rising edge
				if(sclk_re)
					begin
						rx_next = {rx_reg[6:0], miso};
					end
			end
		stop:
			begin
				ncs = 1'b0;
				if(n_reg == 0)
					begin
						if(sclk_re)
							begin
								n_next = n_reg + 1'b1;
							end
					end
				if(n_reg == 1)
					begin
						if(sclk_fe)
							begin
								n_next = n_reg + 1'b1;
							end
					end
				if(n_reg == 2)
					begin
						if(sclk_re)
							begin
								done_tick = 1'b1;
								state_next = idle;
							end
					end
			end
	endcase
	
end

assign spck = (state_reg == data) ? sclk : 1'b0;
assign mosi = tx_reg[7];
assign rhr = rx_reg;

endmodule
