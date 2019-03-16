//	scale_image.v - module will scale image
//	Version:		1.0	
//	Author:			Jagir Charla
//	Last Modified:	14-March-19
//	
//	 Revision History
//	 ----------------
//	 14-March-19		first implementation of scaling
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
//			[13:0] image_addr   - address of 320*240 memory
//			
//////////

module scale_image(
	input				video_on,
	input		[11 :0]	pixel_row,
	input		[11 :0]	pixel_column,
	output	reg	[16 :0]	image_addr,
	output	reg			blank_disp
);


//this is going to be latch design
always@(*)
begin 
	if((video_on == 1'b1) && (pixel_column < 320) && (pixel_row < 240))
	begin
		image_addr = pixel_row * 320 + pixel_column; 
		blank_disp = 0;
	end
	else
	begin
		blank_disp = 1;
	end
end
endmodule
