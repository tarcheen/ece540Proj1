// scale_map_tb.v
// 12 February 2019
//
// Drive the scale_map module for simulation testing

`timescale 1ns/1ns

`include "mfp_ahb_const.vh"

module scale_map_tb;

	reg 			video_on;
	reg [11 :0]		pixel_row;
	reg [11 :0]		pixel_column;
	wire [13 :0]	worldmap_addr;

	
	scale_map my_scale_map(
		.video_on(video_on),
		.pixel_row(pixel_row),
		.pixel_column(pixel_column),
		.worldmap_addr(worldmap_addr)
	);
	
	always 
	begin
		//10 ns seconds clock
		//which is equivalent to 100MHz
		#1 
		pixel_column = pixel_column + 1;
		if(pixel_column >= 1024)
		begin
			pixel_column = 0;
			pixel_row = pixel_row + 1;
			if(pixel_row >= 768)
			begin
				pixel_row = 0;
			end
		end
	end
	
	initial
    begin
		video_on = 1'b1;
		pixel_row = 0;
		pixel_column = 0;
		#20000000
		$stop;
	end
	
endmodule