-- Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2018.2.1 (win64) Build 2288692 Thu Jul 26 18:24:02 MDT 2018
-- Date        : Sat Feb 16 15:29:16 2019
-- Host        : caplab05 running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               n:/Downloads/ECE540/WorkingDirectory/RojoBot/RojoBot.srcs/sources_1/ip/blk_mem_gen_5/blk_mem_gen_5_stub.vhdl
-- Design      : blk_mem_gen_5
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7a100tcsg324-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity blk_mem_gen_5 is
  Port ( 
    clka : in STD_LOGIC;
    addra : in STD_LOGIC_VECTOR ( 3 downto 0 );
    douta : out STD_LOGIC_VECTOR ( 1 downto 0 )
  );

end blk_mem_gen_5;

architecture stub of blk_mem_gen_5 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clka,addra[3:0],douta[1:0]";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "blk_mem_gen_v8_4_1,Vivado 2018.2.1";
begin
end;
