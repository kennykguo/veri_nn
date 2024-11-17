module part1 (Clock, DataIn, DataOut, Address, Write);
	input Clock, Write;
	input [3:0] DataIn;
	output [3:0] DataOut;
	input [4:0] Address;
	
	ram32x4 U1 (Address, Clock, DataIn, Write, DataOut);
endmodule
