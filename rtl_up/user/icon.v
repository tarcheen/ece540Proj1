//	icon.v - module helps to display bot icon
//	Version:		1.0	
//	Author:			Jagir Charla
//	Last Modified:	15-Feb-19
//	
//	 Revision History
//	 ----------------
//	 15-Feb-19		first implementation of icon
//
//	Description:
//	------------
//	 This circuit 
//	
//	 Inputs:
//			[7:0] LocX_reg 		- bots X location
//			[7:0] LocY_reg		- bots Y location
//			[7:0] BotInfo_reg	- bots information movement, decides which icon to show according to orientation
//			[11 :0]	pixel_row	- pixel row to display
//			[11 :0]	pixel_column- pixel row to display
//		
//	 Outputs:
//			[1 :0]	icon_pixel,
//////////

module icon(
	input [7:0] 		LocX_reg,
	input [7:0] 		LocY_reg,
	input [7:0] 		BotInfo_reg,
	input [11 :0] 		pixel_row,
	input [11 :0] 		pixel_column,
	output	reg	[1 :0]	icon_pixel
);


reg [11:0] scaled_row;
reg [11:0] scaled_column;

//this is going to decide the icon
always@(*)
begin 
	//12 bit value,
	//which divides pixel_column by 8
	scaled_column = {3'b0,pixel_column[11:3]};
	//divide by 6
	scaled_row = pixel_row/6;
	
	//check for the location
	//and give value to icon accordingly
	if((scaled_column[7:0] >= LocX_reg) 
		&& (scaled_column[7:0] <= LocX_reg+2)
		&& (scaled_row[7:0] >= LocY_reg)
		&& (scaled_row[7:0] <= LocY_reg+2)
		)
	begin
		icon_pixel = 2'b01;
	end
	else
	begin
		icon_pixel = 2'b0;
	end
end
endmodule
