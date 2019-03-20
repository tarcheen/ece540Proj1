//	photo_sm.v - module will scale image
//	Version:		1.0	
//	Author:			Prasanna Kulkarni,Jagir Charla
//	Last Modified:	16-March-19
//	
//	 Revision History
//	 ----------------
//	 16-March-19		first implementation of photo_sm
//
//	Description:
//	------------
//	
//	 Inputs:
//	 Outputs:
//			
//////////

module photo_sm(
	input				clk,
	input				reset,
	input				start,
	input				ack,
	input				vsync,
	input				wen,
	output	reg 		wen_out,
	output	reg			done,
	output	reg			error
);

	reg [2:0] curr_state;
	reg [2:0] next_state;
	
	localparam SM_RESET = 0;	
    localparam SM_WAIT_FOR_START = 1;
    localparam SM_WAIT_FOR_VSYNC = 2;
    localparam SM_WAIT_FOR_VSYNC_0 = 3;
    localparam SM_WAIT_FOR_VSYNC_1 = 4;
    localparam SM_DONE = 5;
    localparam SM_ERROR = 6;
    
	
	always@(posedge clk)
	begin
		if(reset == 1'b0)
			curr_state <= SM_RESET;
		else
			curr_state <= next_state;
	end
	
	always@(curr_state,start,vsync,ack)
	begin
		case(curr_state)
			SM_RESET:
			begin
				next_state = SM_WAIT_FOR_START;
			end
			
			SM_WAIT_FOR_START:
			begin
				if(start == 1'b1)
					next_state = SM_WAIT_FOR_VSYNC;
			end
			
			SM_WAIT_FOR_VSYNC:
			begin
				if(vsync == 1'b1)
					next_state = SM_WAIT_FOR_VSYNC_0;
			end
			
			SM_WAIT_FOR_VSYNC_0:
			begin
				if(vsync == 1'b0)
					next_state = SM_WAIT_FOR_VSYNC_1;
			end
			
			SM_WAIT_FOR_VSYNC_1:
			begin
				if(vsync == 1'b1)
					next_state = SM_DONE;
			end
			
			SM_DONE:
			begin
				if(ack == 1'b1)
					next_state = SM_WAIT_FOR_START;
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
	
	always@(curr_state,wen)
	begin
		case(curr_state)
			SM_RESET:
			begin
				wen_out = 1'b0;
				done = 1'b0;
				error = 1'b0;
			end
			
			SM_WAIT_FOR_START:
			begin
				wen_out = 1'b0;
				done = 1'b0;
				error = 1'b0;
			end
			
			SM_WAIT_FOR_VSYNC:
			begin
				wen_out = 1'b0;
				done = 1'b0;
				error = 1'b0;
			end
			
			SM_WAIT_FOR_VSYNC_0:
			begin
				wen_out = wen;
				done = 1'b0;
				error = 1'b0;
			end
			
			SM_WAIT_FOR_VSYNC_1:
			begin
				wen_out = wen;
				done = 0;
				error = 1'b0;
			end
			
			SM_DONE:
			begin
				wen_out = 1'b0;
				done = 1'b1;
				error = 1'b0;
			end
			
			SM_ERROR:
			begin
				wen_out = 1'b0;
				done = 1'b0;
				error = 1'b1;
			end
			
			default:
			begin
				wen_out = 1'b0;
				done = 1'b0;
				error = 1'b1;
			end
		endcase
	end

endmodule
