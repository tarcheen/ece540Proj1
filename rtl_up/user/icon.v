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
//			clk 				- clk used for ROM 
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
	input  				clk,
	input [7:0] 		LocX_reg,
	input [7:0] 		LocY_reg,
	input [7:0] 		BotInfo_reg,
	input [11 :0] 		pixel_row,
	input [11 :0] 		pixel_column,
	output	reg	[1 :0]	icon_pixel
);

reg [11:0] scaled_row;
reg [11:0] scaled_column;

//use for addressing the data
reg  [3:0] addr_icon;
reg  [1:0] addr_icon_row;
reg  [1:0] addr_icon_column;

//these arer input data for the mux
//one of them will be choosen based on orientation
wire  [1:0] icon_data_0;
wire  [1:0] icon_data_1;
wire  [1:0] icon_data_2;
wire  [1:0] icon_data_3;
wire  [1:0] icon_data_4;
wire  [1:0] icon_data_5;
wire  [1:0] icon_data_6;
wire  [1:0] icon_data_7;

blk_mem_gen_0 icon_0(
	.addra(addr_icon)
	,.clka(clk)
	,.douta(icon_data_0)
	);
	
blk_mem_gen_1 icon_1(
	.addra(addr_icon)
	,.clka(clk)
	,.douta(icon_data_1)
	);

blk_mem_gen_2 icon_2(
	.addra(addr_icon)
	,.clka(clk)
	,.douta(icon_data_2)
	);
	
blk_mem_gen_3 icon_3(
	.addra(addr_icon)
	,.clka(clk)
	,.douta(icon_data_3)
	);
	
blk_mem_gen_4 icon_4(
	.addra(addr_icon)
	,.clka(clk)
	,.douta(icon_data_4)
	);

blk_mem_gen_5 icon_5(
	.addra(addr_icon)
	,.clka(clk)
	,.douta(icon_data_5)
	);

blk_mem_gen_6 icon_6(
	.addra(addr_icon)
	,.clka(clk)
	,.douta(icon_data_6)
	);

blk_mem_gen_7 icon_7(
	.addra(addr_icon)
	,.clka(clk)
	,.douta(icon_data_7)
	);
	
 
//this is going to decide the icon
always@(*)
begin 
	//12 bit value,
	//which divides pixel_column by 8
	scaled_column = {3'b0,pixel_column[11:3]};
	//divide by 6
	scaled_row = pixel_row/6;
	
	if(scaled_column[7:0] == LocX_reg)
	begin
		addr_icon_column = 2'b00;
	end
	else if(scaled_column[7:0] == LocX_reg+1)
	begin
		addr_icon_column = 2'b01;
	end
	else if(scaled_column[7:0] == LocX_reg+2)
	begin
		addr_icon_column = 2'b10;
	end
	else if(scaled_column[7:0] == LocX_reg+3)
	begin
		addr_icon_column = 2'b11;
	end
	else
	begin
		addr_icon_column = 2'b00;
	end
	
	
	if(scaled_row[7:0] == LocY_reg)
	begin
		addr_icon_row = 2'b00;
	end
	else if(scaled_row[7:0] == LocY_reg+1)
	begin
		addr_icon_row = 2'b01;
	end
	else if(scaled_row[7:0] == LocY_reg+2)
	begin
		addr_icon_row = 2'b10;
	end
	else if(scaled_row[7:0] == LocY_reg+3)
	begin
		addr_icon_row = 2'b11;
	end
	else
	begin
		addr_icon_row = 2'b00;
	end
	
	addr_icon = (addr_icon_row * 4) + addr_icon_column;
	
	//check for the location
	//and give value to icon accordingly
	//considering our icon size is 4*4
	if((scaled_column[7:0] >= LocX_reg) 
		&& (scaled_column[7:0] < LocX_reg+4)
		&& (scaled_row[7:0] >= LocY_reg)
		&& (scaled_row[7:0] < LocY_reg+4)
		)
	begin
		//check for orientation
		case(BotInfo_reg[2:0])
			3'b000:
				icon_pixel = icon_data_0;
			3'b001:
				icon_pixel = icon_data_1;
			3'b010:
				icon_pixel = icon_data_2;
			3'b011:
				icon_pixel = icon_data_3;
			3'b100:
				icon_pixel = icon_data_4;
			3'b101:
				icon_pixel = icon_data_5;
			3'b110:
				icon_pixel = icon_data_6;
			3'b111:
				icon_pixel = icon_data_7;
			default:
				icon_pixel = icon_data_0;
		endcase
	end
	else
	begin
		icon_pixel = 2'b0;
	end
end
endmodule
