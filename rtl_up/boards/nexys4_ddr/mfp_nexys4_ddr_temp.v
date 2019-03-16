// mfp_nexys4_ddr.v
// February 22, 2019
//
// Instantiate the mipsfpga system and rename signals to
// match the GPIO, LEDs and switches on Digilent's (Xilinx)
// Nexys4 DDR board

// Outputs:
// 16 LEDs (IO_LED) 
// Seven segment signals
// VGA signals
// Inputs:
// 16 Slide switches (IO_Switch),
// 5 Pushbuttons (IO_PB): {BTNU, BTND, BTNL, BTNC, BTNR}
//

`include "mfp_ahb_const.vh"

module mfp_nexys4_ddr( 
                        input                   	CLK100MHZ,
                        input                   	CPU_RESETN,
                        input                   	BTNU, BTND, BTNL, BTNC, BTNR, 
                        input  	   [`MFP_N_SW-1 :0] SW,
                        output 	   [`MFP_N_LED-1:0] LED,
						output 						CA, CB, CC, CD, CE, CF, CG,
						output 						DP,
						output     [`MFP_N_SEG-1:0]	AN,
						
						//Signals for VGA
						output     [3			:0]	VGA_R,
						output     [3			:0]	VGA_G,
						output     [3			:0]	VGA_B,
						output     					VGA_HS,
						output     					VGA_VS,
						
                        inout  	   [ 8          :1] JB,
                        input                   	UART_TXD_IN);

	// Press btnCpuReset to reset the processor. 
		
	wire clk_out; 
	//clock for VGA
	wire clk_out_75MHZ; 
	//video_on signal tells us what to do at blanking time
	wire video_on;
	//genetrated from DTG, consumed by scalar block
	wire [11:0] pixel_row;
	wire [11:0] pixel_column;
	//given to memories to access data for memories
	wire [16:0] image_disp_addr;
	//generated from memories, which drives the coloriser
	reg [11:0] image_data;
	wire [11:0] image_data_0;
	wire [11:0] image_data_1;
	wire [11:0] image_data_2;
	wire [11:0] image_data_3;
	
	
	wire tck_in, tck;

	//changes in clock wizard to add clock out of 75MHz
	clk_wiz_0 clk_wiz_0(.clk_in1(CLK100MHZ), .clk_out1(clk_out),.clk_out2(clk_out_75MHZ));
	IBUF IBUF1(.O(tck_in),.I(JB[4]));
	BUFG BUFG1(.O(tck), .I(tck_in));
  
	//signals use for debouncing
	wire CPU_RESETN_DB;
	wire BTNU_DB;
	wire BTND_DB;
	wire BTNL_DB;
	wire BTNC_DB;
	wire BTNR_DB;
	wire [`MFP_N_SW-1 :0] SW_DB;
	
	//instance of debounce
	debounce debounce(
		.clk(clk_out),
		.pbtn_in({CPU_RESETN,BTNU,BTND,BTNL,BTNC,BTNR}),
		.switch_in(SW),
		.pbtn_db({CPU_RESETN_DB,BTNU_DB,BTND_DB,BTNL_DB,BTNC_DB,BTNR_DB}),
		.swtch_db(SW_DB)
	);
	
	//instance of dtg
	//used for VGA
	dtg dtg(
		.clock(clk_out_75MHZ),
		.rst(~CPU_RESETN_DB),
		.horiz_sync(VGA_HS),
		.vert_sync(VGA_VS),
		.video_on(video_on),
		.pixel_row(pixel_row),
		.pixel_column(pixel_column)
	);
	
	//instance of colorizer
	//which actually takes care of coloring
	colorizer colorizer(
		.video_on(video_on),
		.op_pixel(image_data),
		.red(VGA_R),
		.green(VGA_G),
		.blue(VGA_B)
	);
	
	
	//instance of scale_image
	//maps 1024x768 to 640*480
	//and gets the cooresponding address for the pixel
	scale_image scale_image(
		.video_on(video_on),
		.pixel_row(pixel_row),
		.pixel_column(pixel_column),
		.image_addr(image_disp_addr)
	);
	
	blk_mem_gen_0 camera_buffer (
		.clka(clk_out_75MHZ),    	// input wire clka
		.wea(1'b0),      			// input wire [0 : 0] wea
		.addra(image_disp_addr),  	// input wire [18 : 0] addra
		.dina(12'b0),    				// input wire [11 : 0] dina
		.douta(image_data_0)  				// output wire [11 : 0] douta
	);
	
	blk_mem_gen_1 image_1 (
		.clka(clk_out_75MHZ),    	// input wire clka
		.wea(1'b0),      			// input wire [0 : 0] wea
		.addra(image_disp_addr),  	// input wire [18 : 0] addra
		.dina(12'b0),    				// input wire [11 : 0] dina
		.douta(image_data_1)  		// output wire [11 : 0] douta
	);
	
	always@(*)
	begin
		case(SW_DB[1:0])
			2'b00:
				image_data = image_data_0;
			2'b01:
				image_data = image_data_1;
			default:
				image_data = image_data_1;
		endcase
	end
	
	//instance of world_map
	//dual port memory
	//one is used by rojobot
	//other is used for world map pixels
	// world_map world_map(
		// .clka(clk_out_75MHZ),
		// .addra(),
		// .douta(),
		// .clkb(clk_out_75MHZ),
		// .addrb(worldmap_addr),
		// .doutb(worldmap_data)
	// );
	
	mfp_sys mfp_sys(
			        // .SI_Reset_N(CPU_RESETN),
			        .SI_Reset_N(CPU_RESETN_DB),
                    .SI_ClkIn(clk_out),
                    .HADDR(),
                    .HRDATA(),
                    .HWDATA(),
                    .HWRITE(),
					.HSIZE(),
                    .EJ_TRST_N_probe(JB[7]),
                    .EJ_TDI(JB[2]),
                    .EJ_TDO(JB[3]),
                    .EJ_TMS(JB[1]),
                    .EJ_TCK(tck),
                    .SI_ColdReset_N(JB[8]),
                    .EJ_DINT(1'b0),
                    // .IO_Switch(SW),
                    .IO_Switch(SW_DB),
                    // .IO_PB({BTNU, BTND, BTNL, BTNC, BTNR}),
                    .IO_PB({BTNU_DB, BTND_DB, BTNL_DB, BTNC_DB, BTNR_DB}),
                    .IO_LED(LED),
                    .IO_AN(AN),
                    .IO_CA(CA),
                    .IO_CB(CB),
                    .IO_CC(CC),
                    .IO_CD(CD),
                    .IO_CE(CE),
                    .IO_CF(CF),
                    .IO_CG(CG),
                    .IO_DP(DP),
					
                    .UART_RX(UART_TXD_IN));
          
endmodule