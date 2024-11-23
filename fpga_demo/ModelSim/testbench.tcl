# Cleanup previous simulation
quit -sim
if {[file exists work]} {
    vdel -lib work -all
}

# Create work library
vlib work

# Map libraries
vmap work work
vmap altera_mf "C:/intelFPGA_lite/18.1/modelsim_ase/altera/verilog/altera_mf"

# Compile Altera libraries first
vlog -work altera_mf "C:/intelFPGA_lite/18.1/quartus/eda/sim_lib/altera_mf.v"

# Now compile your design files
vlog -work work ../tb_neural_network_top.v
vlog -work work ../neural_network_top.v
vlog -work work ../neural_network.v
vlog -work work ../mnist_drawing_grid.v
vlog -work work ../matrix_multiply.v
vlog -work work ../relu.v
vlog -work work ../argmax.v

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

vlog -work work ../image_memory.v
vlog -work work ../clock_divider.v

vlog -work work ../object_mem.v
vlog -work work ../vga_adapter/vga_adapter.v
vlog -work work ../vga_adapter/vga_address_translator.v
vlog -work work ../vga_adapter/vga_controller.v
vlog -work work ../vga_adapter/vga_pll.v

# Start simulation
vsim -t 1ps -L altera_mf_ver work.tb_neural_network_top

# Add waves for neural_network_top
add wave -noupdate -divider "Neural Network Top Signals"
add wave -position end sim:/tb_neural_network_top/uut/*

# Add waves for neural_network module
add wave -noupdate -divider "Neural Network Module Signals"
add wave -position end sim:/tb_neural_network_top/uut/nn/*

# Add waves for memory addresses and data
add wave -noupdate -divider "Memory Addresses"
add wave -position end sim:/tb_neural_network_top/uut/nn/input_addr
add wave -position end sim:/tb_neural_network_top/uut/nn/weight1_addr
add wave -position end sim:/tb_neural_network_top/uut/nn/weight2_addr
add wave -position end sim:/tb_neural_network_top/uut/nn/weight3_addr
add wave -position end sim:/tb_neural_network_top/uut/nn/weight4_addr

add wave -noupdate -divider "Memory Data"
add wave -position end -radix decimal sim:/tb_neural_network_top/uut/nn/input_data
add wave -position end -radix decimal sim:/tb_neural_network_top/uut/nn/weight1_data
add wave -position end -radix decimal sim:/tb_neural_network_top/uut/nn/weight2_data
add wave -position end -radix decimal sim:/tb_neural_network_top/uut/nn/weight3_data
add wave -position end -radix decimal sim:/tb_neural_network_top/uut/nn/weight4_data

# Add waves for intermediate results
add wave -noupdate -divider "Layer 1 Signals"
add wave -position end sim:/tb_neural_network_top/uut/nn/mm1_*
add wave -position end sim:/tb_neural_network_top/uut/nn/relu1_*

add wave -noupdate -divider "Layer 2 Signals"
add wave -position end sim:/tb_neural_network_top/uut/nn/mm2_*
add wave -position end sim:/tb_neural_network_top/uut/nn/relu2_*

add wave -noupdate -divider "Layer 3 Signals"
add wave -position end sim:/tb_neural_network_top/uut/nn/mm3_*
add wave -position end sim:/tb_neural_network_top/uut/nn/relu3_*

add wave -noupdate -divider "Layer 4 Signals"
add wave -position end sim:/tb_neural_network_top/uut/nn/mm4_*

add wave -noupdate -divider "Control Signals"
add wave -position end sim:/tb_neural_network_top/uut/nn/start_*
add wave -position end sim:/tb_neural_network_top/uut/nn/*_done

add wave -noupdate -divider "State Machine"
add wave -position end -radix unsigned sim:/tb_neural_network_top/uut/nn/current_state
add wave -position end -radix unsigned sim:/tb_neural_network_top/uut/nn/next_state

# Configure wave window
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