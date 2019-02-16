//	scale_map.v - module will scale the 128x128 image to 1024 768
//	Version:		1.0	
//	Author:			Jagir Charla
//	Last Modified:	12-Feb-19
//	
//	 Revision History
//	 ----------------
//	 12-Feb-19		first implementation of scaling
//
//	Description:
//	------------
//	 This circuit scals down the pixel_row and pixel_row
//	
//	 Inputs:
//			video_on            - indicates blanking interval or not, dont increment anything
//			[11:0] pixel_row	- pixel row
//			[11:0] pixel_column	- pixel column
//	 Outputs:
//			[13:0] worldmap_addr- address of 128*128 memory
//			
//////////

module scale_map(
	input				video_on,
	input		[11 :0]	pixel_row,
	input		[11 :0]	pixel_column,
	output	reg	[13 :0]	worldmap_addr
);

//make it 14 bit wide
//cause worldmap_addr is 14 bit wide
reg [13:0] scaled_column;
//make it 11 bit wide, same as pixel_row
reg [11:0] scaled_row;
//make it 18 bit wide, to accomodate 128 multiplier
reg [18:0] scaled_row_multiplied;

//this is going to be latch design
always@(*)
begin 
	if(video_on == 1'b1)
	begin
		//14 bit value,
		//which divides pixel_column by 8
		scaled_column = {5'b0,pixel_column[11:3]};
		//divide by 6
		scaled_row = pixel_row/6;
		//mutiply by 128
		scaled_row_multiplied = scaled_row * 128;
		//this will tell us about the memory which we want to access
		worldmap_addr = scaled_row_multiplied[13:0] + scaled_column;
	end
end
endmodule
