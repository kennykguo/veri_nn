# Cleanup previous simulation
quit -sim
if {[file exists work]} {
    vdel -lib work -all
}

# Create work library
vlib work
vmap work work

# Compile all Verilog files
vlog ../matrix_memory.v
vlog ../image_memory.v
vlog ../matrix_multiply.v
vlog ../tb_matrix_multiply.v

# Start simulation
vsim -t 1ps work.tb_matrix_multiply

# Add waves with specific formatting
add wave -noupdate -divider "Control Signals"
add wave -position insertpoint -radix binary /tb_matrix_multiply/mult/current_state
add wave -position insertpoint -radix binary /tb_matrix_multiply/mult/next_state
add wave -position insertpoint -radix binary /tb_matrix_multiply/start
add wave -position insertpoint -radix binary /tb_matrix_multiply/done
add wave -position insertpoint -radix binary /tb_matrix_multiply/write_enable

add wave -noupdate -divider "Addresses"
add wave -position insertpoint -radix unsigned /tb_matrix_multiply/input_addr
add wave -position insertpoint -radix unsigned /tb_matrix_multiply/weight_addr
add wave -position insertpoint -radix unsigned /tb_matrix_multiply/output_addr

add wave -noupdate -divider "Data"
add wave -position insertpoint -radix hexadecimal /tb_matrix_multiply/input_data
add wave -position insertpoint -radix hexadecimal /tb_matrix_multiply/weight_data
add wave -position insertpoint -radix hexadecimal /tb_matrix_multiply/output_data

add wave -noupdate -divider "Internal Registers"
add wave -position insertpoint -radix unsigned /tb_matrix_multiply/mult/i
add wave -position insertpoint -radix unsigned /tb_matrix_multiply/mult/j
add wave -position insertpoint -radix unsigned /tb_matrix_multiply/mult/p
add wave -position insertpoint -radix hexadecimal /tb_matrix_multiply/mult/temp_sum
# add wave -position insertpoint -radix hexadecimal /tb_matrix_multiply/mult/current_input
# add wave -position insertpoint -radix hexadecimal /tb_matrix_multiply/mult/current_weight
# add wave -position insertpoint -radix hexadecimal /tb_matrix_multiply/mult/mult_result

add wave -noupdate -divider "Memory Contents"
add wave -position insertpoint -radix hexadecimal /tb_matrix_multiply/output_memory

# Configure wave window
configure wave -namecolwidth 200
configure wave -valuecolwidth 150
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2

# Zoom full
wave zoom full

# Run simulation
run -all

