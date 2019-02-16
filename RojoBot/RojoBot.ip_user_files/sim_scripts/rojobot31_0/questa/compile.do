vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xil_defaultlib
vlib questa_lib/msim/xpm

vmap xil_defaultlib questa_lib/msim/xil_defaultlib
vmap xpm questa_lib/msim/xpm

vlog -work xil_defaultlib -64 -sv \
"D:/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \

vcom -work xpm -64 -93 \
"D:/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib -64 \
"../../../../RojoBot.srcs/sources_1/ip/rojobot31_0/src/bot31_if.v" \
"../../../../RojoBot.srcs/sources_1/ip/rojobot31_0/src/bot31_pgm.v" \
"../../../../RojoBot.srcs/sources_1/ip/rojobot31_0/src/kcpsm6.v" \
"../../../../RojoBot.srcs/sources_1/ip/rojobot31_0/src/bot31_top.v" \
"../../../../RojoBot.srcs/sources_1/ip/rojobot31_0/sim/rojobot31_0.v" \

vlog -work xil_defaultlib \
"glbl.v"

