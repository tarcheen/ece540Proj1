`timescale 1ns / 1ps

`timescale 1ns / 1ps

module ov7670_capture_verilog(input pclk,
                              input vsync,
                              input href,
                              input [7:0] d,
                              output [16:0] addr,
                              output [11:0] dout,
                              output we);
                              
    reg [15:0] d_latch = {16{1'b0}};
    reg [16:0] address = {17{1'b0}};
    reg [16:0] address_next = {17{1'b0}};
    reg [1:0] wr_hold = {2{1'b0}};
    
    reg [11:0] dout_temp;
    reg we_temp;
	
	reg [11:0] x_count;
	reg [11:0] y_count;
	reg [10:0] x_new_count;
	reg [10:0] y_new_count;
    
    // assign addr = (y_new_count * 320) + x_new_count;
    assign addr = address;
    assign dout = dout_temp;
    assign we = we_temp;
    
    always@ (posedge pclk)
	begin
		if(vsync == 1)
		begin
			address <= {17{1'b0}};
			// address_next <= {17{1'b0}};
			wr_hold <= {2{1'b0}};
			
			x_count <= 12'b0;
			y_count	<= 12'b0;
		end
		else
		begin
			dout_temp <= {d_latch[15:12],d_latch[10:7],d_latch[4:1]};
			// address <= address_next;
			address <= (y_new_count * 320) + x_new_count;
			
			we_temp <= wr_hold[1];
			wr_hold <= {wr_hold[0], (href && !wr_hold[0])};
			d_latch <= {d_latch [7:0], d};
			
			if(wr_hold[1] == 1)
			begin
				// Here we are wrapping around the primary counts of the 
				// x address and the y address.
				if (x_count == 639)	
					x_count <= 12'd0;
				else	
					x_count <= x_count + 12'd1;
				
				if ((y_count >= 479) && (x_count >= 639))
					y_count <= 12'd0;
				else if (x_count == 639)
					y_count <= y_count + 12'd1;
			end
		end
	end
	
	always@(x_count,y_count)
	begin
		if(x_count[0] == 1'b0)
			x_new_count = x_count[11:1];
		
		if(y_count[0] == 1'b0)
			y_new_count = y_count[11:1];
	end
        
endmodule