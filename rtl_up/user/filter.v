module filter (
	input clk,	
	input reset,	
	input ack_flag,
	input start_flag,
	input  [11:0] data_pixel,
	output [16:0] address_to_read,
	output reg [8:0] x_min, x_max, y_min, y_max,
	output reg done_flag
);

// First we declare the state machine variables.
// First we declare the state machine variables.
localparam SM_RESET = 0;
localparam RESET_XY = 1;	
localparam IDLE = 2;	
localparam ADDR_GEN = 3;
localparam ADDR_GEN_WAIT_1 = 4;
localparam ADDR_GEN_WAIT_2 = 5;
localparam COLOR_DETECT = 6;
localparam CHECK_PIX_OUT = 7;
localparam MIN_MAX = 8;
localparam RESET_PIXEL_OUT = 9;
localparam CHECK_DONE = 10;
localparam LATCH_OP = 11;
localparam DONE = 12;

reg [3:0] CURR_STATE, NEXT_STATE;

//temp reg for x_min and x_max
reg [8:0] x_min_temp, x_max_temp, y_min_temp, y_max_temp;

reg [11:0] x_count;
reg [11:0] y_count;

reg [16:0]address;
reg [0:0] pixel_out;

assign address_to_read = address;

always@(posedge clk) 
begin

	if(reset == 1'b0)
	begin
		x_count <= 0;
		y_count <= 0;
		address <= 0;
	end
	
	else if (CURR_STATE == RESET_XY)
	begin
		x_count <= 0;
		y_count <= 0;
		address <= 0;
	end
	
    else if(CURR_STATE == ADDR_GEN)
	begin
		address <= (y_count * 320) + x_count;
        if (x_count < 9'd319) 
			x_count <= x_count + 1;
		else 
		begin
			if (y_count < 9'd239) 
			begin
				y_count <= y_count + 1;
				x_count <= 0;
			end
			else
			begin
				y_count <= 0;
				x_count <= 0;
			end
		end	
	end
end

// The state switching logic
always @(posedge clk) 
begin
	if (reset == 1'b0)
		CURR_STATE <= SM_RESET;
	else
		CURR_STATE <= NEXT_STATE;
end


// NEXT_STATE Transitioning block
always@(*) begin
	case(CURR_STATE)
		
		SM_RESET:
		begin
			NEXT_STATE = IDLE;			
		end
		
		IDLE: 
		begin
			if (start_flag != 1)
				NEXT_STATE = IDLE;
			else
				NEXT_STATE = RESET_XY;
		end
		
		RESET_XY:
		begin
			NEXT_STATE = ADDR_GEN;
		end
		
		ADDR_GEN:
		begin
			NEXT_STATE = ADDR_GEN_WAIT_1;
		end
		
		ADDR_GEN_WAIT_1:
		begin
			NEXT_STATE = ADDR_GEN_WAIT_2;
		end
		
		ADDR_GEN_WAIT_2:
		begin
			NEXT_STATE = COLOR_DETECT;
		end
		
		COLOR_DETECT: 
		begin
			NEXT_STATE = CHECK_PIX_OUT;			
		end	
		
		CHECK_PIX_OUT:
		begin
			if(pixel_out == 1'b1)
			begin
				NEXT_STATE = MIN_MAX;
			end
			else
			begin
				NEXT_STATE = CHECK_DONE;
			end
		end
	
		MIN_MAX: 
		begin
			NEXT_STATE = RESET_PIXEL_OUT;
		end
		
		RESET_PIXEL_OUT:
		begin
			NEXT_STATE = CHECK_DONE;
		end
		
		CHECK_DONE:
		begin
			if (address >= 17'd76799) 
			begin
				NEXT_STATE = LATCH_OP;
			end
			else
			begin
				NEXT_STATE = ADDR_GEN;
			end
		end
		
		LATCH_OP:
		begin
			NEXT_STATE = DONE;
		end
		
		DONE:
		begin
			if (ack_flag != 1)
				NEXT_STATE = DONE;
			else
				NEXT_STATE = IDLE;
		end
	endcase
end

// Output Generation Logic
always@(*)
begin
	case(CURR_STATE)
	
		SM_RESET:
		begin			
			x_min_temp = 319;
			y_min_temp = 239;
			
			x_max_temp = 0;
			y_max_temp = 0;
			
			x_min = 0;
			x_max = 0;
			y_min = 0;
			y_max = 0;
			
			pixel_out = 0;		
			done_flag = 0;
		end
	
		IDLE: 
		begin
			x_min_temp = 319;
			y_min_temp = 239;
			
			x_max_temp = 0;
			y_max_temp = 0;
			
			pixel_out = 0;
			done_flag = 0;
		end
		
		RESET_XY:
		begin
		end
		
		ADDR_GEN:
		begin
		end
		
		ADDR_GEN_WAIT_1:
		begin
		end
		
		ADDR_GEN_WAIT_2:
		begin
		end
		
		COLOR_DETECT: 
		begin
			if ((data_pixel[7:4] > 4'd12) && (data_pixel[11:8] < 4'd8 ) && (data_pixel[3:0] < 4'd8) )
			begin
				pixel_out = 1'b1;
			end	
			else
			begin
				pixel_out = 1'b0;
			end		
		end
	
		CHECK_PIX_OUT:
		begin
		end
		
		MIN_MAX: 
		begin
			
			if (x_count < x_min_temp ) 
			begin
				x_min_temp = x_count;
			end
			
			if (x_count > x_max_temp) 
			begin
				x_max_temp = x_count;
			end
			
			if (y_count < y_min_temp ) 
			begin
				y_min_temp = y_count;
			end
			
			if (y_count > y_max_temp) 
			begin
				y_max_temp = y_count;
			end
		end
		
		RESET_PIXEL_OUT:
		begin
			pixel_out = 1'b0;
        end
		
		CHECK_DONE:
		begin
        end
		
		LATCH_OP:
		begin
			if(x_min_temp >= 319)
				x_min_temp = 0;
			
			if(y_min_temp >= 239)
				y_min_temp = 0;
		end
		
		DONE:
		begin
			/*x_min = x_min_temp;
			x_max = x_max_temp;
			y_min = y_min_temp;
			y_max = y_max_temp;*/
			
			x_min = 30;
			x_max = 150;
			y_min = 30;
			y_max = 150;
			done_flag = 1;
		end
	endcase
end
endmodule