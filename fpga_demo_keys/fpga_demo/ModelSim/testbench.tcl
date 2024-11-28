# Cleanup previous simulation
quit -sim
if {[file exists work]} {
    vdel -lib work -all
}

# Create work library
vlib work

# Map libraries
vmap work work
vmap altera_mf "C:/DESL/Quartus18/modelsim_ase/altera/verilog/altera_mf"

# Compile Altera libraries first
vlog -work altera_mf "C:/DESL/Quartus18/quartus/eda/sim_lib/altera_mf.v"

# Design files
vlog -work work ../neural_network_top.v
vlog -work work ../tb_neural_network_top.v

vlog -work work ../combined_nn_mnist_grid.v
vlog -work work ../matrix_multiply.v
vlog -work work ../relu.v
vlog -work work ../argmax.v

# Compile memory modules
vlog -work work ../matrix1.v
vlog -work work ../matrix2.v
vlog -work work ../matrix3.v
vlog -work work ../matrix4.v 

vlog -work work ../mm1_memory.v
vlog -work work ../mm2_memory.v
vlog -work work ../mm3_memory.v
vlog -work work ../mm4_memory.v

vlog -work work ../relu1_memory.v
vlog -work work ../relu2_memory.v
vlog -work work ../relu3_memory.v

# Compile image memory and clock divider modules
vlog -work work ../image_memory.v

# Compile other control and VGA modules
vlog -work work ../object_mem.v
vlog -work work ../vga_adapter/vga_adapter.v
vlog -work work ../vga_adapter/vga_address_translator.v
vlog -work work ../vga_adapter/vga_controller.v
vlog -work work ../vga_adapter/vga_pll.v

# Start simulation with proper library and work directory
vsim -t 1ps -L altera_mf_ver work.tb_neural_network_top

# Add waves for neural_network_top
add wave -noupdate -divider "Neural Network Top Signals"
add wave -position end sim:/tb_neural_network_top/uut/*

# Add waves for neural_network module (including submodules)
add wave -noupdate -divider "Neural Network Module Signals"
add wave -position end sim:/tb_neural_network_top/uut/combined_module/*

# Add waves for memory addresses and data (including different layers)
add wave -noupdate -divider "Memory Addresses"
add wave -position end sim:/tb_neural_network_top/uut/combined_module/image_addr
add wave -position end sim:/tb_neural_network_top/uut/combined_module/weight1_addr
add wave -position end sim:/tb_neural_network_top/uut/combined_module/weight2_addr
add wave -position end sim:/tb_neural_network_top/uut/combined_module/weight3_addr
add wave -position end sim:/tb_neural_network_top/uut/combined_module/weight4_addr

add wave -noupdate -divider "Memory Data"
add wave -position end -radix decimal sim:/tb_neural_network_top/uut/combined_module/image_data
add wave -position end -radix decimal sim:/tb_neural_network_top/uut/combined_module/weight1_data
add wave -position end -radix decimal sim:/tb_neural_network_top/uut/combined_module/weight2_data
add wave -position end -radix decimal sim:/tb_neural_network_top/uut/combined_module/weight3_data
add wave -position end -radix decimal sim:/tb_neural_network_top/uut/combined_module/weight4_data

# Add waves for intermediate results (specific to each layer)
add wave -noupdate -divider "Layer 1 Signals"
add wave -position end sim:/tb_neural_network_top/uut/combined_module/mm1_*
add wave -position end sim:/tb_neural_network_top/uut/combined_module/relu1_*

add wave -noupdate -divider "Layer 2 Signals"
add wave -position end sim:/tb_neural_network_top/uut/combined_module/mm2_*
add wave -position end sim:/tb_neural_network_top/uut/combined_module/relu2_*

add wave -noupdate -divider "Layer 3 Signals"
add wave -position end sim:/tb_neural_network_top/uut/combined_module/mm3_*
add wave -position end sim:/tb_neural_network_top/uut/combined_module/relu3_*

add wave -noupdate -divider "Layer 4 Signals"
add wave -position end sim:/tb_neural_network_top/uut/combined_module/mm4_*

# Add waves for control signals
add wave -noupdate -divider "Control Signals"
add wave -position end sim:/tb_neural_network_top/uut/combined_module/start_*
add wave -position end sim:/tb_neural_network_top/uut/combined_module/*_done

# Add waves for state machine
add wave -noupdate -divider "State Machine"
add wave -position end -radix unsigned sim:/tb_neural_network_top/uut/combined_module/current_state
add wave -position end -radix unsigned sim:/tb_neural_network_top/uut/combined_module/next_state

# Add waves for VGA signals (verify output display)
add wave -noupdate -divider "VGA Signals"
add wave -position end sim:/tb_neural_network_top/uut/VGA_R
add wave -position end sim:/tb_neural_network_top/uut/VGA_G
add wave -position end sim:/tb_neural_network_top/uut/VGA_B
add wave -position end sim:/tb_neural_network_top/uut/VGA_HS
add wave -position end sim:/tb_neural_network_top/uut/VGA_VS
add wave -position end sim:/tb_neural_network_top/uut/VGA_BLANK_N
add wave -position end sim:/tb_neural_network_top/uut/VGA_SYNC_N
add wave -position end sim:/tb_neural_network_top/uut/VGA_CLK

# Add waves for HEX displays (to monitor output)
add wave -noupdate -divider "HEX Displays"
add wave -position end sim:/tb_neural_network_top/uut/HEX0
add wave -position end sim:/tb_neural_network_top/uut/HEX1
add wave -position end sim:/tb_neural_network_top/uut/HEX2
add wave -position end sim:/tb_neural_network_top/uut/HEX3
add wave -position end sim:/tb_neural_network_top/uut/HEX4
add wave -position end sim:/tb_neural_network_top/uut/HEX5

# Configure wave window for readability
configure wave -namecolwidth 250
configure wave -valuecolwidth 150
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2

# Run simulation
run -all
