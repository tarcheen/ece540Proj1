// mfp_nexys4_ddr.v
// January 1, 2017
//
// Instantiate the mipsfpga system and rename signals to
// match the GPIO, LEDs and switches on Digilent's (Xilinx)
// Nexys4 DDR board

// Outputs:
// 16 LEDs (IO_LED) 
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
	//given to world_map to access data for map
	wire [13:0] worldmap_addr;
	//generated from world_map, which drives the coloriser
	wire [1:0] worldmap_data;
	
	//address for rojobot, generated from rojobot IP
	wire [13:0] rojo_addr;
	//generated from world_map, given to rojobot
	//based on this rojo bot updates its sensor values
	//and we can read those from registers
	wire [1:0] rojo_data;
	
	//controlled by AHB lite
	wire [7:0] MotCtl_in;
	wire [7:0] LocX_reg;
	wire [7:0] LocY_reg;
	wire [7:0] Sensors_reg;
	wire [7:0] BotInfo_reg;
	wire [7:0] Bot_Config_reg;
	
	//use for handshaking
	wire upd_sysregs;
	reg upd_sysregs_sync;
	wire io_int_ack;
	
	//comes fron icon module
	//icon data
	wire [1:0] icon_data;
	
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
		.world_pixel(worldmap_data),
		.icon_pixel(icon_data),
		.red(VGA_R),
		.green(VGA_G),
		.blue(VGA_B)
	);
	
	//instance of icon
	//decides when to show icon on screen
	icon icon(
		.LocX_reg(LocX_reg),
		.LocY_reg(LocY_reg),
		.BotInfo_reg(BotInfo_reg),
		.pixel_row(pixel_row),
		.pixel_column(pixel_column),
		.icon_pixel(icon_data)
	);
	
	scale_map scale_map(
		.video_on(video_on),
		.pixel_row(pixel_row),
		.pixel_column(pixel_column),
		.worldmap_addr(worldmap_addr)
	);
	
	world_map world_map(
		.clka(clk_out_75MHZ),
		.addra(rojo_addr),
		.douta(rojo_data),
		.clkb(clk_out_75MHZ),
		.addrb(worldmap_addr),
		.doutb(worldmap_data)
	);
	
	assign Bot_Config_reg = 8'b0;
	
	//instance of rojo bot
	rojobot31_0 rojo_bot (
		.MotCtl_in(MotCtl_in),     	// input wire [7 : 0] MotCtl_in
		.LocX_reg(LocX_reg),       	// output wire [7 : 0] LocX_reg
		.LocY_reg(LocY_reg),       	// output wire [7 : 0] LocY_reg
		.Sensors_reg(Sensors_reg),	// output wire [7 : 0] Sensors_reg
		.BotInfo_reg(BotInfo_reg),	// output wire [7 : 0] BotInfo_reg
		.worldmap_addr(rojo_addr),	// output wire [13 : 0] worldmap_addr
		.worldmap_data(rojo_data),	// input wire [1 : 0] worldmap_data
		.clk_in(clk_out_75MHZ),     // input wire clk_in
		.reset(~CPU_RESETN_DB),     // input wire reset
		.upd_sysregs(upd_sysregs),	// output wire upd_sysregs
		.Bot_Config_reg(Bot_Config_reg)	// input wire [7 : 0] Bot_Config_reg
	);
	
	//handshaking flipflop
	always@(posedge clk_out) begin
		if(io_int_ack == 1'b1) begin
			upd_sysregs_sync <= 1'b0;
		end
		else if (upd_sysregs == 1'b1) begin
			upd_sysregs_sync <= 1'b1;
		end
		else begin
			upd_sysregs_sync <= upd_sysregs_sync;
		end
	end
	
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
					.PORT_BOTINFO     		({LocX_reg,LocY_reg,Sensors_reg,BotInfo_reg}),
					.PORT_BOTUPDT     		(upd_sysregs_sync),
					.PORT_BOTCTRL     		(MotCtl_in),
					.PORT_INTACK      		(io_int_ack),
                    .UART_RX(UART_TXD_IN));
          
endmodule