// debounce_tb.v
// 09 February 2019
//
// Drive the debounce module for simulation testing

`timescale 1ns/1ns

`include "mfp_ahb_const.vh"

module debounce_tb;

	reg 		clk;
	reg [5:0]	pbtn_in;
	// reg [15:0]	switch_in;
	wire [5:0]	pbtn_db;
	// wire 		swtch_db;
					
	
	debounce my_debounce(
		.clk(clk),
		.pbtn_in(pbtn_in),
		.switch_in(),
		.pbtn_db(pbtn_db),
		.swtch_db()
	);
	
	always 
	begin
		//10 ns seconds clock
		//which is equivalent to 100MHz
		#5 clk = ~clk;
	end
	
	initial
    begin
		clk = 1'b0;
		pbtn_in = 6'b000000;
		#500000000
		pbtn_in = 6'b111111;
		#500000000
		pbtn_in = 6'b000000;
		#500000000
		pbtn_in = 6'b111111;
		#500000000
		pbtn_in = 6'b000000;
		#500000000
		$stop;
	end
	
endmodule