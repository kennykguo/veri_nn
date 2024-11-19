onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -label CLOCK_50 -radix binary /testbench/CLOCK_50
add wave -noupdate -label KEY -radix binary /testbench/KEY
add wave -noupdate -label SW -radix binary /testbench/SW

# Add signals related to the mouse and PS/2 interface
add wave -noupdate -label mouse_x -radix hexadecimal /testbench/U1/mouse_x
add wave -noupdate -label mouse_y -radix hexadecimal /testbench/U1/mouse_y
add wave -noupdate -label PS2_CLK -radix binary /testbench/U1/PS2_CLK
add wave -noupdate -label PS2_DAT -radix binary /testbench/U1/PS2_DAT
add wave -noupdate -label left_button -radix binary /testbench/U1/left_button
add wave -noupdate -label right_button -radix binary /testbench/U1/right_button
add wave -noupdate -label debug -radix binary /testbench/U1/debug


# Add signals for the hexadecimal displays
add wave -noupdate -label HEX0 -radix hexadecimal /testbench/U1/HEX0
add wave -noupdate -label HEX1 -radix hexadecimal /testbench/U1/HEX1
add wave -noupdate -label HEX2 -radix hexadecimal /testbench/U1/HEX2
add wave -noupdate -label HEX3 -radix hexadecimal /testbench/U1/HEX3


add wave -noupdate -label VGA_R -radix hexadecimal /testbench/VGA_R
add wave -noupdate -label VGA_G -radix hexadecimal /testbench/VGA_G
add wave -noupdate -label VGA_B -radix hexadecimal /testbench/VGA_B
add wave -noupdate -label VGA_HS -radix binary /testbench/VGA_HS
add wave -noupdate -label VGA_VS -radix binary /testbench/VGA_VS
add wave -noupdate -label VGA_BLANK_N -radix binary /testbench/VGA_BLANK_N
add wave -noupdate -label VGA_SYNC_N -radix binary /testbench/VGA_SYNC_N
add wave -noupdate -label VGA_CLK -radix binary /testbench/VGA_CLK
add wave -noupdate -divider vga_demo
add wave -noupdate -label x -radix hexadecimal /testbench/U1/X
add wave -noupdate -label y -radix hexadecimal /testbench/U1/Y
add wave -noupdate -label xC -radix hexadecimal /testbench/U1/XC
add wave -noupdate -label yC -radix hexadecimal /testbench/U1/YC
add wave -noupdate -label object_address -radix hexadecimal /testbench/U1/U6/address
add wave -noupdate -label object_color -radix hexadecimal /testbench/U1/U6/q
add wave -noupdate -divider vga_adapter
add wave -noupdate -label colour -radix hexadecimal /testbench/U1/VGA/colour
add wave -noupdate -label x -radix hexadecimal /testbench/U1/VGA/x
add wave -noupdate -label y -radix hexadecimal /testbench/U1/VGA/y
add wave -noupdate -label plot -radix hexadecimal /testbench/U1/VGA/plot
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
