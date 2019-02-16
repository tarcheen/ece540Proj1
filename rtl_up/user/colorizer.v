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
//			[1:0] icon_pixel		- based on encoding generate one of the color
//	 Outputs:
//			[3:0] red	- red 	color value
//			[3:0] green	- green color value
//			[3:0] blue	- blue 	color value
//			
//////////

module colorizer(
	input				video_on,
	input		[1 :0]	world_pixel,
	input		[1 :0]	icon_pixel,
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
	else
	begin
		//if icon_pixel is 00 then comes from 
		//world pixel
		if(icon_pixel == 2'b00)
		begin
			case(world_pixel)
				//background, in our case white
				//FIXME can we configure this via software
				2'b00:
				begin
					red 	= 4'b1111;
					green 	= 4'b1111;
					blue 	= 4'b1111;
				end
				
				//blck line
				2'b01:
				begin
					red 	= 4'b0000;
					green 	= 4'b0000;
					blue 	= 4'b0000;
				end
				
				//FIXME can we make this configurable
				//like from a register or something
				//obstruction, red color
				2'b10:
				begin
					red 	= 4'b1111;
					green 	= 4'b0000;
					blue 	= 4'b0000;
				end
				
				default:
				begin
					red 	= 4'b0000;
					green 	= 4'b0000;
					blue 	= 4'b0000;
				end
			endcase
		end
		//otherwise get value from ICON
		else
		begin
			case(icon_pixel)
				//FIXME can we do it from register
				//icon color 1, lets say yellow
				2'b01:
				begin
					red 	= 4'b1111;
					green 	= 4'b1111;
					blue 	= 4'b0000;
				end
				
				//FIXME can we do it from register
				//icon color 2, lets say green
				2'b10:
				begin
					red 	= 4'b0000;
					green 	= 4'b1111;
					blue 	= 4'b0000;
				end
				
				//FIXME can we do it from register
				//icon color 3, lets say blue
				2'b11:
				begin
					red 	= 4'b0000;
					green 	= 4'b0000;
					blue 	= 4'b1111;
				end
				
				//should never come here
				default:
				begin
					red 	= 4'b0000;
					green 	= 4'b0000;
					blue 	= 4'b0000;
				end
			endcase
		end
	end
end

endmodule
