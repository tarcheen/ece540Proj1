// mfp_de0_cv.v
// January 1, 2017
//
// Instantiate the mipsfpga system and rename signals to
// match the GPIO, LEDs and switches on Altera's DE0-CV FPGA
// board.
//
// Altera's DE0-CV board:
// Outputs:
// 10 LEDs (IO_LED) 
// Inputs:
// 10 slide switches (IO_Switch), 
// 3 pushbutton switches (IO_PB)
//
// Note the right-most pushbutton IO_PB[0] (KEY[0] on the board)
// is used to reset the processor.
//
// Other interfaces:
//   parts of GPIO_1[11:0] connect to the EJTAG signals.
//   GPIO_1[31] connects to the UART interface.

`include "mfp_ahb_const.vh"

module mfp_de0_cv(
                   input                    CLOCK_50,
                   input  [`MFP_N_SW-1 : 0] SW,
                   input  [`MFP_N_PB-1 : 0] KEY,
                   output [`MFP_N_LED-1: 0] LEDR,
                   inout  [31          : 0] GPIO_1);

  // Use KEY[0] (push button switch 0) for SI_Reset_N. 
  // Note: KEY[0] must be pushed down (held low) to reset the processor. 

/*  
  wire clk_out;
  
  altpll0 altpll0 (.refclk(CLOCK_50), .outclk_0(clk_out), .rst(1'b0));
	
//  altpll0 altpll0 (.inclk0(CLOCK_50), .c0(clk_out));

*/
  mfp_sys mfp_sys(
                            .SI_Reset_N(KEY[0]),
//                            .SI_ClkIn(clk_out),
                            .SI_ClkIn(CLOCK_50),
                            .HADDR(),
                            .HRDATA(),
                            .HWDATA(),
                            .HWRITE(),
                            .HSIZE(),
                            .EJ_TRST_N_probe(GPIO_1[11]),
                            .EJ_TDI(GPIO_1[9]),
                            .EJ_TDO(GPIO_1[7]),
                            .EJ_TMS(GPIO_1[5]),
                            .EJ_TCK(GPIO_1[3]),
                            .SI_ColdReset_N(GPIO_1[1]),
                            .EJ_DINT(GPIO_1[0]),
                            .IO_Switch(SW),
                            .IO_PB(~KEY),
                            .IO_LED(LEDR),
                            .UART_RX(GPIO_1[31]));
          
endmodule


