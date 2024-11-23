module neural_network_top (
    input CLOCK_50,
    input [3:0] KEY,
    input [9:0] SW,
    input PS2_CLK,
    input PS2_DAT,
    output [7:0] VGA_R, VGA_G, VGA_B,
    output VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK,
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
    output [9:0] LEDR
);

    // Internal signals
    wire clk;              // Clock signal for the neural network
    wire clk_slow;         // Divided clock
    wire start;            // Start signal
    wire resetn;           // Active low reset
    wire init;
    wire done;             // Done signal from the neural network
    wire [3:0] argmax_output;  // Neural network classification output
    wire [783:0] pixel_data;   // Internal signal for pixel data

    // State signals for debugging
    wire [3:0] current_state;
    wire [3:0] next_state;

    // Clock divider instance
    clock_divider clk_div (
        .clk_in(CLOCK_50),
        .clk_out(clk_slow),
        .DIVISOR(32'd500)
    );
	 
	assign LEDR[9] = start;
	assign LEDR[3:0] = current_state;
	 
    // Assign control signals
    assign clk = clk_slow;
    assign start = ~KEY[0];
    assign resetn = ~SW[9];  // Active low reset
    assign init = ~KEY[1];

    // MNIST Drawing Grid instance
    mnist_drawing_grid drawing_grid (
        .CLOCK_50(CLOCK_50),
        .SW(SW),
        .PS2_CLK(PS2_CLK),
        .PS2_DAT(PS2_DAT),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK),
        .HEX0(HEX2),  // Connect HEX0 for displaying the neural network result
        .HEX1(HEX3),
        .HEX2(HEX4),
        .HEX3(HEX5),
        .pixel_memory(pixel_data)  // Provide pixel data to the neural network
    );

    // Neural network instance
    neural_network nn (
        .clk(clk),
        .resetn(resetn),
        .start(start),
        .pixel_data(pixel_data),  // Connect pixel data from mnist_drawing_grid
        .done(done),
        .current_state(current_state),
        .next_state(next_state),
        .argmax_output(argmax_output)
    );

    // Seven segment decoder logic with intermediate reg
    reg [6:0] seg7_display;
    assign HEX0 = seg7_display;

    always @(*) begin
        if (!resetn) begin
            seg7_display = 7'b1111111; // Turn off all segments when reset
        end else begin
            case (argmax_output)
                4'd0: seg7_display = 7'b1000000; // Display '0'
                4'd1: seg7_display = 7'b1111001; // Display '1'
                4'd2: seg7_display = 7'b0100100; // Display '2'
                4'd3: seg7_display = 7'b0110000; // Display '3'
                4'd4: seg7_display = 7'b0011001; // Display '4'
                4'd5: seg7_display = 7'b0010010; // Display '5'
                4'd6: seg7_display = 7'b0000010; // Display '6'
                4'd7: seg7_display = 7'b1111000; // Display '7'
                4'd8: seg7_display = 7'b0000000; // Display '8'
                4'd9: seg7_display = 7'b0010000; // Display '9'
                4'd10: seg7_display = 7'b01111111; // Default
                default: seg7_display = 7'b1111111; // Turn off segments for invalid input
            endcase
        end
    end

    // Optional coordinate display (HEX1)
    assign HEX1 = 7'b1111111;  // Turn off HEX1 if unused
endmodule

