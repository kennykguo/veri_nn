# testbench.tcl - Automated ModelSim TCL script

# Create the work library if it doesn't exist
if {[file exists work] == 0} {
    vlib work
}

# Compile the Verilog source files
vlog -sv signed_arithmetic_fpga.v
vlog -sv signed_arithmetic_tb.v

# Load the testbench module and run the simulation
vsim signed_arithmetic_tb

# Run the simulation and display output
run -all

# Exit ModelSim after completion
quit
