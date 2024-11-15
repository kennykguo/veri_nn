onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -label Clock -radix binary /testbench/Clock
add wave -noupdate -label Write -radix binary /testbench/Write
add wave -noupdate -label DataIn -radix hexadecimal /testbench/DataIn
add wave -noupdate -label Address -radix hexadecimal /testbench/Address
add wave -noupdate -label DataOut -radix hexadecimal /testbench/DataOut
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {10000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 80
configure wave -valuecolwidth 40
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {120 ns}
