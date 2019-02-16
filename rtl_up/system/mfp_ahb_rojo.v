// mfp_ahb_rojo.v
//
// ROJO memory mapped module for Altera's DE2-115 and 
// Digilent's (Xilinx) Nexys4-DDR board


`include "mfp_ahb_const.vh"

module mfp_ahb_rojo(
    input                        HCLK,
    input                        HRESETn,
    input      [  7          :0] HADDR,
    input      [  1          :0] HTRANS,
    input      [ 31          :0] HWDATA,
    input                        HWRITE,
    input                        HSEL,
    output reg [ 31          :0] HRDATA,

	// memory-mapped rojo
	//will come from rojobot and go to rojobot
	input 	   [31 :0] 			 PORT_BOTINFO,
    input       			 	 PORT_BOTUPDT,
	output reg [7  :0] 			 PORT_BOTCTRL,
	output reg 			 		 PORT_INTACK
);

	reg  [7:0]  HADDR_d;
	reg         HWRITE_d;
	reg         HSEL_d;
	reg  [1:0]  HTRANS_d;
	wire        we;            // write enable

	// delay HADDR, HWRITE, HSEL, and HTRANS to align with HWDATA for writing
	always @ (posedge HCLK) 
	begin
		HADDR_d  <= HADDR;
		HWRITE_d <= HWRITE;
		HSEL_d   <= HSEL;
		HTRANS_d <= HTRANS;
	end
  
	// overall write enable signal
	assign we = (HTRANS_d != `HTRANS_IDLE) & HSEL_d & HWRITE_d;

    always @(posedge HCLK or negedge HRESETn) begin
		if (~HRESETn) begin
			PORT_BOTCTRL <= 8'h0;  
			PORT_INTACK <= 1'b0;  
		end 
		else if (we) begin
			case (HADDR_d)
				`PORT_BOTCTRL_IONUM: PORT_BOTCTRL <= HWDATA[7:0];
				`PORT_INTACK_IONUM: PORT_INTACK <= HWDATA[0];
			endcase
		end
	end
    
	always @(posedge HCLK or negedge HRESETn) begin
		if (~HRESETn)
			HRDATA <= 32'h0;
		else begin
			case (HADDR)
				`PORT_BOTINFO_IONUM: HRDATA <= PORT_BOTINFO;
				`PORT_BOTUPDT_IONUM: HRDATA <= {31'b0,PORT_BOTUPDT};
				default:    HRDATA <= 32'h00000000;
			endcase
		end
	end 
endmodule

