// This code implements a simple dual-port memory
// 
// inputs: CLOCK_50 is the clock, KEY0 is Resetn, SW3-SW0 provides data to 
// write into memory.
// SW8-SW4 provides the memory address for writing, SW9 is the memory Write input.
// outputs: 7-seg display HEX5-4 displays the write address, and HEX3-2 shows the read 
// address. HEX1 displays the write data and HEX0 shows the read data. 
// LEDR shows the status of the SW switches.
module part4 (CLOCK_50, KEY, SW, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0, LEDR);
	input CLOCK_50;
	input [0:0] KEY;
	input [9:0] SW;
	output [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;
	output [9:0] LEDR;

	wire Clock, Resetn, Write, Write_sync;
	wire [4:0] Write_address, Write_address_sync;
	wire [3:0] DataIn, DataIn_sync, DataOut;

	assign Resetn = KEY[0];
	assign Clock = CLOCK_50;

	// synchronize all asynchronous inputs to the clock
	regne #(.n(1)) wr_sync_reg(SW[9], Clock, Resetn, 1'b1, Write_sync);
	regne #(.n(1)) wr_reg(Write_sync, Clock, Resetn, 1'b1, Write);
	regne #(.n(5)) addr_sync_reg(SW[8:4], Clock, Resetn, 1'b1, Write_address_sync);
	regne #(.n(5)) addr_reg(Write_address_sync, Clock, Resetn, 1'b1, Write_address);
	regne #(.n(4)) din_sync_reg(SW[3:0], Clock, Resetn, 1'b1, DataIn_sync);
	regne #(.n(4)) din_reg(DataIn_sync, Clock, Resetn, 1'b1, DataIn);

	// one second cycle counter
	parameter m = 14;   // use 25 for DE1-SoC, use 18 for DESim 
	reg [m-1:0] slow_count;
	reg [4:0] Read_address; // cycles from addresses 0 to 31 at one second per address

	// Create a 1Hz 5-bit address counter
	// A large counter to produce a 1 second (approx) enable
	always @(posedge Clock)
		if (Resetn == 0)
			slow_count <= {m{1'b0}};
        else
		    slow_count <= slow_count + 1'b1;
	// the read address counter
	always @ (posedge Clock)
		if (Resetn == 0)
			Read_address <= 5'b0;
		else if (slow_count == {m{1'b1}})
			Read_address <= Read_address + 1'b1;

	// instantiate memory module
	// module ram32x4 (clock, data, rdaddress, wraddress, wren, q);
	ram32x4 U1 (Clock, DataIn, Read_address, Write_address, Write, DataOut);

	// display the data input, data output, and addresses on the 7-segs
	hex7seg digit5 ({3'b0, Write_address[4]}, HEX5);
	hex7seg digit4 (Write_address[3:0], HEX4);
	hex7seg digit3 ({3'b0, Read_address[4]}, HEX3);
	hex7seg digit2 (Read_address[3:0], HEX2);
	hex7seg digit1 (DataIn[3:0], HEX1);
	hex7seg digit0 (DataOut[3:0], HEX0);
	
	assign LEDR[3:0] = DataIn;
	assign LEDR[8:4] = Write_address;
	assign LEDR[9] = Write;
endmodule

module regne (R, Clock, Resetn, E, Q);
	parameter n = 7;
	input [n-1:0] R;
	input Clock, Resetn, E;
	output [n-1:0] Q;
	reg [n-1:0] Q;	
	
	always @(posedge Clock)
		if (Resetn == 0)
			Q <= {n{1'b0}};
		else if (E)
			Q <= R;
endmodule

module hex7seg (hex, display);
    input [3:0] hex;
    output [6:0] display;

    reg [6:0] display;

    /*
     *       0  
     *      ---  
     *     |   |
     *    5|   |1
     *     | 6 |
     *      ---  
     *     |   |
     *    4|   |2
     *     |   |
     *      ---  
     *       3  
     */
    always @ (hex)
        case (hex)
            4'h0: display = 7'b1000000;
            4'h1: display = 7'b1111001;
            4'h2: display = 7'b0100100;
            4'h3: display = 7'b0110000;
            4'h4: display = 7'b0011001;
            4'h5: display = 7'b0010010;
            4'h6: display = 7'b0000010;
            4'h7: display = 7'b1111000;
            4'h8: display = 7'b0000000;
            4'h9: display = 7'b0011000;
            4'hA: display = 7'b0001000;
            4'hB: display = 7'b0000011;
            4'hC: display = 7'b1000110;
            4'hD: display = 7'b0100001;
            4'hE: display = 7'b0000110;
            4'hF: display = 7'b0001110;
        endcase
endmodule
