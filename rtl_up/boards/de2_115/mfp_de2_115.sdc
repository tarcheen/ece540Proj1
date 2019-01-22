
# Clock constraints

create_clock -name "CLOCK_50" -period 20.000ns [get_ports {CLOCK_50}] -waveform {0.000 10.000}

# Virtual input clock
create_clock -name "clk_invirt" -period 20.0 -waveform {0.0 10.0}

# Virtual output clock
create_clock -name "clk_outvirt" -period 20.0 -waveform {0.0 10.0}

# EJTAG virtual clock
create_clock -name "tck" -period 20.0 [get_ports {EX_IO[2]}] -waveform {0.0 10.0}

# cut all paths to and from "clk_outvirt", "clk_invirt", and "tck"
set_clock_groups -exclusive -group "clk_outvirt"
set_clock_groups -exclusive -group "clk_invirt"
set_clock_groups -exclusive -group "tck"

# Automatically constrain PLL and other generated clocks
derive_pll_clocks -create_base_clocks

# Automatically calculate clock uncertainty to jitter and other effects.
derive_clock_uncertainty

# tsu/th constraints

set_input_delay -clock "clk_invirt" -max 20ns [get_ports {CLOCK_50}] 
set_input_delay -clock "clk_invirt" -min 0.000ns [get_ports {CLOCK_50}] 
set_input_delay -clock "clk_invirt" -max 20ns [get_ports {KEY[*]}] 
set_input_delay -clock "clk_invirt" -min 0.000ns [get_ports {KEY[*]}] 
set_input_delay -clock "clk_invirt" -max 20ns [get_ports {SW[*]}] 
set_input_delay -clock "clk_invirt" -min 0.000ns [get_ports {SW[*]}] 
set_input_delay -clock "clk_invirt" -max 20ns [get_ports {EX_IO[0]}] 
set_input_delay -clock "clk_invirt" -min 0.000ns [get_ports {EX_IO[0]}] 
set_input_delay -clock "clk_invirt" -max 20ns [get_ports {EX_IO[1]}] 
set_input_delay -clock "clk_invirt" -min 0.000ns [get_ports {EX_IO[1]}] 
set_input_delay -clock "clk_invirt" -max 20ns [get_ports {EX_IO[3]}] 
set_input_delay -clock "clk_invirt" -min 0.000ns [get_ports {EX_IO[3]}] 
set_input_delay -clock "clk_invirt" -max 20ns [get_ports {EX_IO[5]}] 
set_input_delay -clock "clk_invirt" -min 0.000ns [get_ports {EX_IO[5]}] 
set_input_delay -clock "clk_invirt" -max 20ns [get_ports {EX_IO[6]}] 
set_input_delay -clock "clk_invirt" -min 0.000ns [get_ports {EX_IO[6]}] 
set_input_delay -clock "clk_invirt" -max 20ns [get_ports {GPIO[31]}] 
set_input_delay -clock "clk_invirt" -min 0.000ns [get_ports {GPIO[31]}] 


# tco constraints

set_output_delay -clock "clk_outvirt" -max 20ns [get_ports {LEDR[*]}] 
set_output_delay -clock "clk_outvirt" -min -0.000ns [get_ports {LEDR[*]}] 
set_output_delay -clock "clk_outvirt" -max 20ns [get_ports {EX_IO[4]}] 
set_output_delay -clock "clk_outvirt" -min -0.000ns [get_ports {EX_IO[4]}] 


# tpd constraints

