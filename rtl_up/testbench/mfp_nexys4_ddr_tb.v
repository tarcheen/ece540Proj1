// mfp_nexys4_ddr_tb.v
// 08 February 2019
//
// Drive the mfp_nexys4_ddr module for simulation testing

`timescale 1ns/1ns

`include "mfp_ahb_const.vh"

module mfp_nexys4_ddr_tb;

	reg			CLK100MHZ;
	reg			CPU_RESETN;
	wire [3:0]	VGA_R;
	wire [3:0]	VGA_G;
	wire [3:0]	VGA_B;
	wire		VGA_HS; 
	wire		VGA_VS; 
					
    mfp_nexys4_ddr my_mfp_nexys4_ddr (.CLK100MHZ(CLK100MHZ),
                 .CPU_RESETN(CPU_RESETN),
				 .BTNU(),
				 .BTND(),
				 .BTNL(),
				 .BTNC(),
				 .BTNR(),
				 .SW(),
				 .LED(),
				 .CA(), 
				 .CB(), 
				 .CC(), 
				 .CD(), 
				 .CE(), 
				 .CF(), 
				 .CG(),
				 .DP(),
				 .AN(),
				 .VGA_R(VGA_R),
				 .VGA_G(VGA_G),
				 .VGA_B(VGA_B),
				 .VGA_HS(VGA_HS),
				 .VGA_VS(VGA_VS),
				 .JB(),
				 .UART_TXD_IN()
    );
	
	always 
	begin
		//10 ns seconds clock
		//which is equivalent to 100MHz
		#5 CLK100MHZ = ~CLK100MHZ;
	end
	
	initial
    begin
		CLK100MHZ = 1'b0;
		CPU_RESETN = 1'b0;
		#1000
		CPU_RESETN = 1'b1;
		#5000000
		#5000000
		#5000000
		#2000000
		//watch simulation for 100000 ns
		//there will be atleast 10000 clock pulses
		//atleast 7 rows should be there
		#100000
		$stop;
	end
	
endmodule