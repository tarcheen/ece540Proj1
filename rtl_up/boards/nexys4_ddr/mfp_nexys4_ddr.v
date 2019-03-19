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
	
	///////////////////////////////////
	
	//camera related signals
	wire done_config; //Indicator of configuration status
	
	//Capture and VGA
    wire [16:0] frame_addr;
    reg [11:0] frame_pixel;
    wire [16:0] capture_addr;
    wire [11:0] capture_data;
    wire capture_we;
    reg capture_we_1;
    reg capture_we_2;
	
	//useful for writing to image
	wire image_write_sel;
	
	/////////////////////////////////////////////
	
	//////////////////////////////////////////////
	//select which image to display
	//negate of that will be , where to write
	//FSM op
	reg image_sel;
	//will come from filter block
	wire [16:0] filter_read_addr;
	
	reg [16:0] image_0_read_addr;
	reg [16:0] image_1_read_addr;
	
	//generated from memories, which drives the coloriser and filter block
	wire [11:0] image_data_0;
	wire [11:0] image_data_1;
	
	//and filter data is used by filter block
	reg [11:0] filter_read_data;
	/////////////////////////////////////////////////
	
	/////////////////////////////////////////////////
	//signals for main state machine
	//state variables
	reg [2:0] curr_state;
	reg [2:0] next_state;
	
	//start capture
	//output of main FSM
	reg photo_start;
	//wait till its done, will come from some vlock
	wire photo_done;
	//acknowledge it
	//output of FSM
	reg photo_ack;
	
	//hand shaking signals for filter
	reg filter_start;
	wire filter_done;
	reg filter_ack;
	
	//hand shaking signals for min and max
	reg min_max_start;
	wire min_max_done;
	reg min_max_ack;
	//////////////////////////////////////////////////////
		
	////////////////////////////////////////////////////////
	//signal for filter block 
	//should come from filter block
	//and map to block memories 
	wire filtered_we;
	wire [16:0] filter_write_addr;
	wire filter_write_data;
	
	//signal for min and max block
	wire [16:0] min_max_read_addr;
	wire min_max_read_data;
	
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
		LED[1] = image_sel;
		LED[2] = default_flag;
	end
	
										   
	mfp_ahb_sevensegdec debug(.data({1'b1,2'b00,curr_state}), .seg({DP,CA,CB,CC,CD,CE,CF,CG}));
	
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
			.wea(capture_we_1),
			.addra(capture_addr),
			.dina(capture_data),
			.clkb(clk_out_25MHZ),
			.addrb(image_0_read_addr),
			.doutb(image_data_0)
        );
		
	blk_mem_gen_1 fb2(
			.clka(cam_pck),
			.wea(capture_we_2),
			.addra(capture_addr),
			.dina(capture_data),
			.clkb(clk_out_25MHZ),
			.addrb(image_1_read_addr),
			.doutb(image_data_1)
        );
		
	blk_mem_gen_3 bw_image (
		.clka(clk_out_25MHZ),    	// run on 25 MHz
		.wea(filtered_we),      	// comes from filter block
		.addra(filter_write_addr),  // comes from filter block
		.dina(filter_write_data),  	// comes from filter block
		.clkb(clk_out_25MHZ),    	// run on 25 MHz
		.addrb(min_max_read_addr),  // comes from min max block
		.doutb(min_max_read_data)  	// comes from min max block
	);
	
	//this block decides which image to be displyed
	//reading logic should go here
	always@(image_sel,image_data_0,image_data_1,
			frame_addr,filter_read_addr)
	begin
		if(image_sel == 1'b0)
		begin
			frame_pixel = image_data_0;
			filter_read_data = image_data_1;
			image_0_read_addr = frame_addr;
			image_1_read_addr = filter_read_addr;
		end
		else
		begin
			frame_pixel = image_data_1;		
			filter_read_data = image_data_0;
			image_0_read_addr = filter_read_addr;
			image_1_read_addr = frame_addr;
		end
	end
	
	assign image_write_sel = ~image_sel;
	
	assign filter_read_addr = 0;
	
	always@(image_write_sel,capture_we)
	begin
		if(image_write_sel == 1'b0)
		begin
			capture_we_1 = capture_we;
			capture_we_2 = 1'b0;
		end
		else
		begin
			capture_we_1 = 1'b0;
			capture_we_2 = capture_we;
		end
	end
	
	//FIXME remove these assign statemenets
	//when we connect the nets to idividual blocks
	
	//states of main state machine
	localparam SM_RESET = 0;		
    localparam SM_TAKE_PHOTO_START = 1;
    localparam SM_TAKE_PHOTO_EXEC = 2;
    localparam SM_TAKE_PHOTO_DONE = 3;
    localparam SM_TAKE_PHOTO_ACK = 4;
    localparam SM_CHANGE_DISP_IMAGE_0 = 5;
    localparam SM_CHANGE_DISP_IMAGE_1 = 6;
	
	reg [17:0] delay_counter;
	
	
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
	
	always@(posedge clk_out_25MHZ)
	begin
		if(CPU_RESETN_DB == 1'b0)
			delay_counter <= 18'd0;
		else
			delay_counter <= delay_counter + 18'd1;
	end
	
	//next state logic
	always@(curr_state,photo_done,filter_done,min_max_done,delay_counter)
	begin
		case(curr_state)
			SM_RESET:
			begin
				next_state = SM_TAKE_PHOTO_START;
			end
			
			SM_TAKE_PHOTO_START:
			begin
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
				if(image_sel == 1'b1)
					next_state = SM_CHANGE_DISP_IMAGE_0;
				else
					next_state = SM_CHANGE_DISP_IMAGE_1;
			end
			
			SM_CHANGE_DISP_IMAGE_0:
			begin
				next_state = SM_TAKE_PHOTO_START;
			end
			
			SM_CHANGE_DISP_IMAGE_1:
			begin
				next_state = SM_TAKE_PHOTO_START;
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
				image_sel = 1'b1;
				default_flag = 1'b0;
			end
			
			SM_TAKE_PHOTO_START:
			begin
				photo_start = 1'b1;
				photo_ack = 1'b0;
				default_flag = 1'b0;
			end
			
			SM_TAKE_PHOTO_EXEC:
			begin
				photo_start = 1'b1;
				photo_ack = 1'b0;
				default_flag = 1'b0;
			end
			
			SM_TAKE_PHOTO_DONE:
			begin
				photo_start = 1'b0;
				photo_ack = 1'b0;
				default_flag = 1'b0;
			end
			
			SM_TAKE_PHOTO_ACK:
			begin
				photo_start = 1'b0;
				photo_ack = 1'b1;
				default_flag = 1'b0;
			end
			
			SM_CHANGE_DISP_IMAGE_0:
			begin
				image_sel = 1'b0;
				default_flag = 1'b0;
			end
			
			SM_CHANGE_DISP_IMAGE_1:
			begin
				image_sel = 1'b1;
				default_flag = 1'b0;
			end
			
			default:
			begin
				default_flag = 1'b1;
			end
		endcase
	end
	
	wire capture_we_inter;
	// assign capture_we = capture_we_inter;
	
	
	photo_sm photo_sm(
		.reset(CPU_RESETN_DB),
		.start(photo_start),
		.clk(cam_pck),
		.ack(photo_ack),
		.vsync(cam_vs),
		.wen(capture_we_inter),
		.wen_out(capture_we),
		.done(photo_done)
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