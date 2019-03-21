//	overlap_image.v - module helps to display super imposed image
//	Version:		1.0	
//	Author:			Jagir Charla
//	Last Modified:	19-March-19
//	
//	 Revision History
//	 ----------------
//	 19-March-19		first implementation of image overlap
//
//	Description:
//	------------
//	 This circuit 
//	
//	 Inputs:
//			
//		
//	 Outputs:
//			[1 :0]	icon_pixel,
//////////

module overlap_image(
	input [8:0] 		x_min,
	input [8:0] 		x_max,
	input [8:0] 		y_min,
	input [8:0] 		y_max,
	input [8:0] 		x_cen,
	input [8:0] 		y_cen,
	input [11 :0] 		pixel_row,
	input [11 :0] 		pixel_column,
	output	reg	[2 :0]	swap_pixel
);

always@(*)
begin
	if((pixel_column >= {3'b0,x_min}) && (pixel_column < {3'b0,x_cen}) 
		&&(pixel_row >= {3'b0,y_min}) && (pixel_row < {3'b0,y_cen}))
	begin
		swap_pixel = 3'b001;
	end
	else if((pixel_column >= {3'b0,x_cen}) && (pixel_column < {3'b0,x_max}) 
		&&(pixel_row >= {3'b0,y_min}) && (pixel_row < {3'b0,y_cen}))
	begin
		swap_pixel = 3'b010;
	end
	else if((pixel_column >= {3'b0,x_min}) && (pixel_column < {3'b0,x_cen}) 
		&&(pixel_row >= {3'b0,y_cen}) && (pixel_row < {3'b0,y_max}))
	begin
		swap_pixel = 3'b011;
	end
	else if((pixel_column >= {3'b0,x_cen}) && (pixel_column < {3'b0,x_max})
		&&(pixel_row >= {3'b0,y_cen}) && (pixel_row < {3'b0,y_max}))
	begin
		swap_pixel = 3'b100;
	end
	else
	begin
		swap_pixel = 3'b000;
	end
	/*
	if((pixel_column >= {3'b0,x_min}) && (pixel_column < {3'b0,x_max}) 
		&&(pixel_row >= {3'b0,y_min}) && (pixel_row < {3'b0,y_max}))
	begin
		swap_pixel = 3'b100;
	end
	else
	begin
		swap_pixel = 3'b000;
	end*/
end
endmodule
