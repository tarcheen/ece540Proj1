-makelib xcelium_lib/xil_defaultlib -sv \
  "D:/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
-endlib
-makelib xcelium_lib/xpm \
  "D:/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../RojoBot.srcs/sources_1/ip/rojobot31_0/src/bot31_if.v" \
  "../../../../RojoBot.srcs/sources_1/ip/rojobot31_0/src/bot31_pgm.v" \
  "../../../../RojoBot.srcs/sources_1/ip/rojobot31_0/src/kcpsm6.v" \
  "../../../../RojoBot.srcs/sources_1/ip/rojobot31_0/src/bot31_top.v" \
  "../../../../RojoBot.srcs/sources_1/ip/rojobot31_0/sim/rojobot31_0.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  glbl.v
-endlib

