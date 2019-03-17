`timescale 1ns / 1ps

module ov7670_capture_verilog(input pclk,
                              input vsync,
                              input href,
                              input [7:0] d,
                              output [18:0] addr,
                              output [11:0] dout,
                              output we);
                              
    reg [15:0] d_latch = {16{1'b0}};
    reg [18:0] address = {19{1'b0}};
    reg [18:0] address_next = {19{1'b0}};
    reg [1:0] wr_hold = {2{1'b0}};
    
    reg [11:0] dout_temp;
    reg we_temp;
	
	reg [11:0] x_count;
	reg [11:0] y_count;
	reg [11:0] x_new_count;
	reg [11:0] y_new_count;
    
    assign addr = address;
    assign dout = dout_temp;
    assign we = we_temp;
    
    always@ (posedge pclk)
	begin
		if(vsync == 1)
		begin
			address <= {19{1'b0}};
			address_next <= {19{1'b0}};
			wr_hold <= {2{1'b0}};
			
			x_count <= 12'b0;
			x_new_count <= 12'b0;
			y_count 	<= 12'b0;
			y_new_count <= 12'b0;
		end
		else
		begin
			dout_temp <= {d_latch[15:12],d_latch[10:7],d_latch[4:1]};
			address <= address_next;
			
			we_temp <= wr_hold[1];
			wr_hold <= {wr_hold[0], (href && !wr_hold[0])};
			d_latch <= {d_latch [7:0], d};
			
			if(wr_hold[1] == 1)
			begin
				// Here we are wrapping around the primary counts of the 
				// x address and the y address.
				if (x_count < 640) 
				begin
					x_count <= x_count + 1;
					if(x_count[0] == 1'b0)
						x_new_count <= x_new_count + 1;
					else
						x_new_count <= x_new_count;
				end
				else 
				begin
					x_count <= 0;
					if (y_count< 480)
					begin
						y_count <= y_count + 1;	
						if (y_count[0] == 1'b0)
							y_new_count <= y_new_count + 1;
						else
							y_new_count <= y_new_count;
					end
					else
						y_count <= 0;
				end
				address_next <= (y_new_count * 320) + x_new_count;
			end
		end
	end
        
endmodule
