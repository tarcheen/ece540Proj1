// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.2.1 (win64) Build 2288692 Thu Jul 26 18:24:02 MDT 2018
// Date        : Fri Feb 15 19:50:03 2019
// Host        : caplab05 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               n:/Downloads/ECE540/WorkingDirectory/RojoBot/RojoBot.srcs/sources_1/ip/blk_mem_gen_0/blk_mem_gen_0_stub.v
// Design      : blk_mem_gen_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_1,Vivado 2018.2.1" *)
module blk_mem_gen_0(clka, addra, douta)
/* synthesis syn_black_box black_box_pad_pin="clka,addra[3:0],douta[1:0]" */;
  input clka;
  input [3:0]addra;
  output [1:0]douta;
endmodule
