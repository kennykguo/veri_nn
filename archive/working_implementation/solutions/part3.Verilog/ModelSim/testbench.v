`timescale 1ns / 1ps

module testbench ( );

	parameter CLOCK_PERIOD = 20;

    reg [0:0] KEY, Write;	
	reg [9:0] SW;
    wire [6:0] HEX5, HEX4, HEX2, HEX0;
    wire [9:0] LEDR;

	initial begin
        KEY <= 1'b0;
	end // initial
	always @ (*)
	begin : Clock_Generator
		#((CLOCK_PERIOD) / 2) KEY <= ~KEY;
	end
	
	initial begin
        SW[9] <= 1'b1; // writing
        SW[8:4] <= 5'd0; SW[3:0] <= 4'b1111;
	end // initial

	initial begin
        #20 SW[8:4] <= 5'd1; SW[3:0] <= 4'b1110;
        #20 SW[8:4] <= 5'd2; SW[3:0] <= 4'b1101;
        #20 SW[8:4] <= 5'd3; SW[3:0] <= 4'b1100;
        #20 SW[8:4] <= 5'd4; SW[3:0] <= 4'b1011;
        #20 SW[9] <= 1'b0; // reading
        #20 SW[8:4] <= 5'd0;
        #20 SW[8:4] <= 5'd1;
        #20 SW[8:4] <= 5'd2;
        #20 SW[8:4] <= 5'd3;
        #20 SW[8:4] <= 5'd4;
	end // initial

	part3 U1 (KEY, SW, HEX5, HEX4, HEX2, HEX0, LEDR);

endmodule
