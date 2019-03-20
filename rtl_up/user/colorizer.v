//	colorizer.v - will decide what to display
//	it should be in sync with dtg
//	Version:		1.0	
//	Author:			Jagir Charla
//	Last Modified:	07-Feb-19
//	
//	 Revision History
//	 ----------------
//	 07-Feb-19		first implementation of colorizer
//
//	Description:
//	------------
//	 This circuit outputs color to VGA connector
//	
//	 Inputs:
//			video_on            - indicates blanking interval or not
//			[1:0] world_pixel	- based on encoding generate one of the color
//			[11 :0]	op_pixel	- based on encoding generate one of the color
//	 Outputs:
//			[3:0] red	- red 	color value
//			[3:0] green	- green color value
//			[3:0] blue	- blue 	color value
//			
//////////

module colorizer(
	input				video_on,
	input		[11 :0]	op_pixel,
	input				blank_disp,
	input		[2:0]	superimpose_pixel,
	input		[3:0]	top_left_r,
	input		[3:0]	top_left_g,
	input		[3:0]	top_left_b,
	input		[3:0]	top_right_r,
	input		[3:0]	top_right_g,
	input		[3:0]	top_right_b,
	input		[3:0]	bottom_left_r,
	input		[3:0]	bottom_left_g,
	input		[3:0]	bottom_left_b,
	input		[3:0]	bottom_right_r,
	input		[3:0]	bottom_right_g,
	input		[3:0]	bottom_right_b,
	output	reg	[3 :0]	red, green, blue
);

//this is going to be combinational design
always@(*)
begin
	//if video_on is low
	//output should be black
	if(video_on == 1'b0)
	begin
		//black color
		red 	= 4'b0000;
		green 	= 4'b0000;
		blue 	= 4'b0000;
	end
	//else we should decide between world or icon
	else if((blank_disp == 1'b0) && (superimpose_pixel == 3'b0))
	begin
		//if icon_pixel is 00 then comes from 
		//world pixel
		red = op_pixel[11:8];
		green = op_pixel[7:4];
		blue = op_pixel[3:0];
	end
	else if((blank_disp == 1'b0) && (superimpose_pixel != 3'b0))
	begin
		case(superimpose_pixel)
			3'b001:
			begin
				red = top_left_r;
				green = top_left_g;
				blue = top_left_b;
			end
			
			3'b010:
			begin
				red = top_right_r;
				green = top_right_g;
				blue = top_right_b;
			end
			
			3'b011:
			begin
				red = bottom_left_r;
				green = bottom_left_g;
				blue = bottom_left_b;
			end
			
			3'b100:
			begin
				red = bottom_right_r;
				green = bottom_right_g;
				blue = bottom_right_b;
			end
		endcase
	end
	else
	begin
		red = 4'b0;
		green = 4'b0;
		blue = 4'b0;
	end
end

endmodule
