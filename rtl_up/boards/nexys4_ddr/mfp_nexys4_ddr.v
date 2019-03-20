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
                        input                   		CLK100MHZ,
                        input                   		CPU_RESETN,
                        input                   		BTNU, BTND, BTNL, BTNC, BTNR, 
                        input  	   [`MFP_N_SW-1 :0] 	SW,
                        output 	   reg [`MFP_N_LED-1:0] LED,
						output 						CA, CB, CC, CD, CE, CF, CG,
						output 						DP,
						output     	reg [`MFP_N_SEG-1:0]	AN,
						
						//Signals for VGA
						output     [3			:0]	VGA_R,
						output     [3			:0]	VGA_G,
						output     [3			:0]	VGA_B,
						output     					VGA_HS,
						output     					VGA_VS,
						
						//camera module
						output 						cam_xck,
						output 						cam_scl,
						inout 						cam_sda,
						input 		[7:0] 			cam_data,
						input 						cam_vs,
						input 						cam_hs,
						input 						cam_pck,
						
                        inout  	   [ 8          :1] JB,
                        input                   	UART_TXD_IN);

		
	// Press btnCpuReset to reset the processor. 
	//signals use for debouncing
	wire CPU_RESETN_DB;
	wire BTNU_DB;
	wire BTND_DB;
	wire BTNL_DB;
	wire BTNC_DB;
	wire BTNR_DB;
	wire [`MFP_N_SW-1 :0] SW_DB;	
		
		
	//clock for MIPS
	wire clk_out; 
	//clock for VGA and other faster modules
	wire clk_out_75MHZ;
	//clock for camera module
	wire clk_out_25MHZ;
	
	wire tck_in, tck;
	
	/////////////////////////////////////////////
	
	//camera related signals
	wire done_config; //Indicator of configuration status
	
	//Capture and VGA
    wire [16:0] frame_addr;
    wire [11:0] frame_pixel;
    wire [16:0] capture_addr;
    wire [11:0] capture_data;
    wire capture_we;

	//////////////////////////////////////////////
	
	wire [16:0] filter_read_addr;
	//and filter data is used by filter block
	wire [11:0] filter_read_data;
	
	////////////////////////////////////////////////
	//signals for main state machine
	//state variables
	reg [3:0] curr_state;
	reg [3:0] next_state;
	
	//start capture
	//output of main FSM
	reg photo_start;
	//wait till its done, will come from some vlock
	wire photo_started;
	wire photo_done;
	//acknowledge it
	//output of FSM
	reg photo_ack;
	wire photo_error;
	
	//hand shaking signals for min and max
	reg min_max_start;
	wire min_max_done;
	reg min_max_ack;
		
	////////////////////////////////////////////////////////
	
	//outputs of min and max module
	wire [8:0] x_min;
	wire [8:0] x_max;

	wire [8:0] y_min;
	wire [8:0] y_max;

	//inferred latches for x_min,x_max,y_min,y_max
	reg [8:0] x_min_l;
	reg [8:0] x_max_l;

	reg [8:0] y_min_l;
	reg [8:0] y_max_l;

	////////////////////////////////////////////////////////
	
	IBUF IBUF1(.O(tck_in),.I(JB[4]));
	BUFG BUFG1(.O(tck), .I(tck_in));
	
	//instance of debounce
	debounce debounce(
		.clk(clk_out),
		.pbtn_in({CPU_RESETN,BTNU,BTND,BTNL,BTNC,BTNR}),
		.switch_in(SW),
		.pbtn_db({CPU_RESETN_DB,BTNU_DB,BTND_DB,BTNL_DB,BTNC_DB,BTNR_DB}),
		.swtch_db(SW_DB)
	);
	
	//changes in clock wizard to add clock out of 75MHz
	clk_wiz_0 clk_wiz_0(.clk_in1(CLK100MHZ), .clk_out1(clk_out), .clk_out2(clk_out_75MHZ)
										   , .clk_out3(clk_out_25MHZ));
	
	//for debugging
	reg default_flag;
	always@(*)
	begin
		AN[0] = 1'b0;
		LED[0] = done_config;
		LED[1] = default_flag;
		LED[2] = photo_started;
		LED[3] = photo_done;
	end
	
										   
	mfp_ahb_sevensegdec debug(.data({1'b1,1'b0,curr_state}), .seg({DP,CA,CB,CC,CD,CE,CF,CG}));
	
	//video_on signal tells us what to do at blanking time
	wire video_on;
	//genetrated from DTG, consumed by image_scale block
	wire [11:0] pixel_row;
	wire [11:0] pixel_column;
	
	//instance of dtg
	//used for VGA
	dtg dtg(
		.clock(clk_out_25MHZ),
		.rst(~CPU_RESETN_DB),
		.horiz_sync(VGA_HS),
		.vert_sync(VGA_VS),
		.video_on(video_on),
		.pixel_row(pixel_row),
		.pixel_column(pixel_column)
	);
	
	//blank disp comes from scalar block only
	//to disable the display for desired location
	wire blank_disp;
	
	//instance of scale_image
	//maps 1024x768 to 640*480
	//and gets the cooresponding address for the pixel
	//this is used to display background
	scale_image scale_image(
		.video_on(video_on),
		.pixel_row(pixel_row),
		.pixel_column(pixel_column),
		.image_addr(frame_addr),
		.blank_disp(blank_disp)
	);
	
	//instance of colorizer
	//which actually takes care of coloring
	//FIXME make changes in coloriser
	//just like rojobot
	colorizer colorizer(
		.video_on(video_on),
		.blank_disp(blank_disp),
		.op_pixel(frame_pixel),
		.red(VGA_R),
		.green(VGA_G),
		.blue(VGA_B)
	);
	
	assign cam_xck = clk_out_25MHZ;
	
	//camera config module
	camera_configure CCONF(
        .clk(clk_out_25MHZ),
        .start(SW_DB[15]),
        .sioc(cam_scl),
        .siod(cam_sda),
        .done(done_config)
        );
		
	blk_mem_gen_0 fb1(
			.clka(cam_pck),
			.wea(capture_we),
			.addra(capture_addr),
			.dina(capture_data),
			.clkb(clk_out_25MHZ),
			.addrb(frame_addr),
			.doutb(frame_pixel)
        );
		
	blk_mem_gen_1 fb2(
			.clka(cam_pck),
			.wea(capture_we),
			.addra(capture_addr),
			.dina(capture_data),
			.clkb(clk_out_25MHZ),
			.addrb(filter_read_addr),
			.doutb(filter_read_data)
        );
		
	
	
	//FIXME remove these assign statemenets
	//when we connect the nets to idividual blocks
	assign filter_read_addr = 0;
	
	//states of main state machine
	localparam SM_RESET = 0;		
    localparam SM_TAKE_PHOTO_START = 1;
    localparam SM_TAKE_PHOTO_STARTED = 2;
    localparam SM_TAKE_PHOTO_EXEC = 3;
    localparam SM_TAKE_PHOTO_DONE = 4;
    localparam SM_TAKE_PHOTO_ACK = 5;
    localparam SM_MIN_MAX_START = 6;
    localparam SM_MIN_MAX_EXEC = 7;
    localparam SM_MIN_MAX_DONE = 8;
    localparam SM_MIN_MAX_ACK = 9;
    localparam SM_ERROR = 10;
	
	//my fsm block
	//this block is the main executor
	//clock block of moore design
	always@(posedge clk_out_25MHZ)
	begin
		if(CPU_RESETN_DB == 1'b0)
			curr_state <= SM_RESET;
		else
			curr_state <= next_state;
	end
	
	//next state logic
	always@(curr_state,photo_started,photo_done,min_max_done)
	begin
		case(curr_state)
			SM_RESET:
			begin
				next_state = SM_TAKE_PHOTO_START;
			end
			
			SM_TAKE_PHOTO_START:
			begin
				next_state = SM_TAKE_PHOTO_STARTED;
			end
			
			SM_TAKE_PHOTO_STARTED:
			begin
				if(photo_started == 1'b1)
					next_state = SM_TAKE_PHOTO_EXEC;
			end
			
			SM_TAKE_PHOTO_EXEC:
			begin
				if(photo_done == 1'b1)
					next_state = SM_TAKE_PHOTO_DONE;
			end
			
			SM_TAKE_PHOTO_DONE:
			begin
				next_state = SM_TAKE_PHOTO_ACK;
			end
			
			SM_TAKE_PHOTO_ACK:
			begin
				next_state = SM_MIN_MAX_START;
			end	
			
			SM_MIN_MAX_START:
			begin
				next_state = SM_MIN_MAX_EXEC;
			end	
			
			SM_MIN_MAX_EXEC:
			begin
				next_state = SM_MIN_MAX_DONE;
			end	
			
			SM_MIN_MAX_DONE:
			begin
				next_state = SM_MIN_MAX_ACK;
			end
			
			SM_MIN_MAX_ACK:
			begin
				next_state = SM_TAKE_PHOTO_START;
			end	
			
			SM_ERROR:
			begin
			end	
			
			default:
			begin
				next_state = SM_ERROR;
			end
		endcase
	end
	
	//OFL for the main state machine
	always@(curr_state)
	begin
		case(curr_state)
			SM_RESET:
			begin
				photo_start = 1'b0;
				photo_ack = 1'b0;
				default_flag = 1'b0;
			end
			
			SM_TAKE_PHOTO_START:
			begin
				photo_start = 1'b1;
				photo_ack = 1'b0;
				default_flag = 1'b0;
			end
			
			SM_TAKE_PHOTO_STARTED:
			begin
				photo_start = 1'b1;
				photo_ack = 1'b0;
				default_flag = 1'b0;
			end
			
			SM_TAKE_PHOTO_EXEC:
			begin
				photo_start = 1'b0;
				photo_ack = 1'b0;
				default_flag = 1'b0;
			end
			
			SM_TAKE_PHOTO_DONE:
			begin
				photo_start = 1'b0;
				photo_ack = 1'b1;
				default_flag = 1'b0;
			end
			
			SM_TAKE_PHOTO_ACK:
			begin
				photo_start = 1'b0;
				photo_ack = 1'b1;
				default_flag = 1'b0;
			end
					
			SM_MIN_MAX_START:
			begin
				photo_start = 1'b0;
				photo_ack = 1'b1;
				default_flag = 1'b0;
			end
			
			SM_MIN_MAX_EXEC:
			begin
				photo_start = 1'b0;
				photo_ack = 1'b1;
				default_flag = 1'b0;
			end
			
			SM_MIN_MAX_DONE:
			begin
				photo_start = 1'b0;
				photo_ack = 1'b1;
				default_flag = 1'b0;
			end
			
			SM_MIN_MAX_ACK:
			begin
				photo_start = 1'b0;
				photo_ack = 1'b0;
				default_flag = 1'b0;
			end
			
			SM_ERROR:
			begin
				photo_start = 1'b0;
				photo_ack = 1'b0;
				default_flag = 1'b1;
			end

			default:
			begin
				photo_start = 1'b0;
				photo_ack = 1'b0;
				default_flag = 1'b1;
			end
		endcase
	end
	
	
	wire capture_we_inter;
	assign capture_we = capture_we_inter & photo_en;
	// assign photo_done = 1'b1;
	
	
	photo_sm photo_sm(
		.clk(cam_pck),
		.reset(CPU_RESETN_DB),
		.start(photo_start),
		.ack(photo_ack),
		.vsync(cam_vs),
		.wen(photo_en),
		.started(photo_started),
		.done(photo_done),
		.error(photo_error)
	);
		
	ov7670_capture_verilog cap1(
        .pclk(cam_pck),
        .vsync(cam_vs),
        .href(cam_hs),
        .d(cam_data),
        .addr(capture_addr),
        .dout(capture_data),
        .we(capture_we_inter));
	
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
                    // .IO_LED(LED),
                    // .IO_AN(AN),
                    // .IO_CA(CA),
                    // .IO_CB(CB),
                    // .IO_CC(CC),
                    // .IO_CD(CD),
                    // .IO_CE(CE),
                    // .IO_CF(CF),
                    // .IO_CG(CG),
                    // .IO_DP(DP),
					
					.IO_LED(),
                    .IO_AN(),
                    .IO_CA(),
                    .IO_CB(),
                    .IO_CC(),
                    .IO_CD(),
                    .IO_CE(),
                    .IO_CF(),
                    .IO_CG(),
                    .IO_DP(),

					
                    .UART_RX(UART_TXD_IN));
          
endmodule