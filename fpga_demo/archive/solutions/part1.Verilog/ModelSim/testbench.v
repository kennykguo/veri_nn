`timescale 1ns / 1ps

module testbench ( );

	parameter CLOCK_PERIOD = 20;

    reg Clock, Write;	
	reg [3:0] DataIn;
	reg [4:0] Address;
    wire [3:0] DataOut;

	initial begin
        Clock <= 1'b0;
	end // initial
	always @ (*)
	begin : Clock_Generator
		#((CLOCK_PERIOD) / 2) Clock <= ~Clock;
	end
	
	initial begin
        Write <= 1'b0;
        DataIn <= 4'b1010;
	end // initial

	initial begin
        Address <= 5'b0;
        #20 Address <= 5'b1;
        #20 Address <= 5'b10;
        #20 Address <= 5'b10000; Write <= 1'b1;
        #20 Write <= 1'b0; Address <= 5'b11;
        #20 Address <= 5'b10000;
	end // initial

	part1 U1 (Clock, DataIn, DataOut, Address, Write);

endmodule
