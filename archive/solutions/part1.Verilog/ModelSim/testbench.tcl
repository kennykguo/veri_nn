# stop any simulation that is currently running
quit -sim

# if simulating with a MIF file, copy it to the working folder. Assumes image.colour.mif
if {[file exists ../ram32x4.mif]} {
	file delete ram32x4.mif
	file copy ../ram32x4.mif .
}

# create the default "work" library
vlib work;

# compile the Verilog source code in the parent folder
vlog ../part1.v ../ram32x4.v

# compile the Verilog code of the testbench
vlog *.v

# start the Simulator, including some libraries that may be needed
vsim work.testbench -Lf 220model -Lf altera_mf_ver -Lf verilog
# show waveforms specified in wave.do
do wave.do
# advance the simulation the desired amount of time
run 120 ns
