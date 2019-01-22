// mfp_basys3.v
// 1 Jan 2017
//
// Instantiate the mipsfpga system and rename signals to
// match GPIO, LEDs and switches on Digilent's (Xilinx)
// Basys3 board

// Digilent's (Xilinx) Basys3 board:
// Inputs:
// 16 slide switches (IO_Switch[15:0]),
// 5 pushbutton switches (IO_PB): {BTNU, BTND, BTNL, BTNC, BTNR}
// Outputs:
// 16 LEDs (IO_LED[15:0]) 
//
// System Outputs:
// EJTAG interface to Bus Blaster (JB port)
// UART interface for loading program memory (RsRx)

`include "mfp_ahb_const.vh"

module mfp_basys3( 
                  input                   clk,
                  input                   btnU, btnD, btnL, btnC, btnR, 
                  input  [`MFP_N_SW-1 :0] sw,
                  output [`MFP_N_LED-1:0] led,
                  inout  [ 5          :0] JB,
                  input                   RsRx);


  // Press btnC to reset the processor.  
  wire clk_out; 
  wire tck_in, tck;
  
  clk_wiz_0 clk_wiz_0(.clk_in1(clk), .clk_out1(clk_out));
  IBUF IBUF1(.O(tck_in),.I(JB[3]));
  BUFG BUFG1(.O(tck), .I(tck_in));

  
  mfp_sys mfp_sys(
			      .SI_Reset_N(~btnC),
                  .SI_ClkIn(clk_out),
                  .HADDR(),
                  .HRDATA(),
                  .HWDATA(),
                  .HWRITE(),
                  .HSIZE(),
                  .EJ_TRST_N_probe(JB[4]),
                  .EJ_TDI(JB[1]),
                  .EJ_TDO(JB[2]),
                  .EJ_TMS(JB[0]),
                  .EJ_TCK(tck),
                  .SI_ColdReset_N(JB[5]),
                  .EJ_DINT(1'b0),
                  .IO_Switch({2'b0,sw}),
                  .IO_PB({btnU, btnD, btnL, 1'b0, btnR}),
                  .IO_LED(led),
                  .UART_RX(RsRx));
          
endmodule

