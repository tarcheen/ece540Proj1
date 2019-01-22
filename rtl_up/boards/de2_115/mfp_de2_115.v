// mfp_de2_115.v
// January 1, 2017
//
// Instantiate the mipsfpga system and rename signals to
// match the GPIO, LEDs and switches on Altera's DE2-115 FPGA
// board.
//
// Altera's DE2-115 board:
// Outputs:
// 18 LEDs (IO_LED) 
// Inputs:
// 18 slide switches (IO_Switch), 4 pushbutton switches (IO_PB[3:0])
//
// Note the right-most pushbutton IO_PB[0] (KEY[0] on the board)
// is used to reset the processor.
//
// Other interfaces:
//   EXT_IO[6:0] connects to the EJTAG signals.
//   GPIO[31] connects to the UART interface.


`include "mfp_ahb_const.vh"

module mfp_de2_115(
                   input                    CLOCK_50,
                   input  [`MFP_N_SW-1 : 0] SW,
                   input  [`MFP_N_PB-1 : 0] KEY,
                   output [`MFP_N_LED-1: 0] LEDR,
                   inout  [6           : 0] EX_IO,
                   input  [31          :31] GPIO);

  // Use KEY[0] (push button switch 0) for SI_Reset_N. 
  // Note: KEY[0] must be pushed down (held low) to reset the processor. 
          
  wire clk_out;
  
  altpll0 altpll0 (.inclk0(CLOCK_50), .c0(clk_out));


  mfp_sys mfp_sys(
                            .SI_Reset_N(KEY[0]),
                            .SI_ClkIn(clk_out),
                            .HADDR(),
                            .HRDATA(),
                            .HWDATA(),
                            .HWRITE(),
                            .HSIZE(),
                            .EJ_TRST_N_probe(EX_IO[6]),
                            .EJ_TDI(EX_IO[5]),
                            .EJ_TDO(EX_IO[4]),
                            .EJ_TMS(EX_IO[3]),
                            .EJ_TCK(EX_IO[2]),
                            .SI_ColdReset_N(EX_IO[1]),
                            .EJ_DINT(EX_IO[0]),
                            .IO_Switch(SW),
                            .IO_PB(~KEY),
                            .IO_LED(LEDR),
                            .UART_RX(GPIO[31]));
          
endmodule


