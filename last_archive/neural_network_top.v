module neural_network_top (
    input CLOCK_50,
    input [3:0] KEY,
    input [9:0] SW,
    // input PS2_CLK,
    // input PS2_DAT,
    // VGA outputs
    output [7:0] VGA_R, VGA_G, VGA_B,
    output VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK,
    // LED displays
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
    output [9:0] LEDR
);


    // Internal signals     
    wire clk_slow; // Slower clock goes into nn FSM    
    wire start; // Starts sequence     
    wire resetn; // Active-low reset

    
    // Drawing grid signals 
    wire on; // Turns on the grid
	 wire draw; // Starts drawing
    wire done; // Done signal indicating done forward pass

    // Memory interface signals (interfaces with image module instantiated in drawing grid module)
    wire [15:0] image_read_addr;
    wire [31:0] image_data_out;

	 
    // State signals for debugging
    wire [3:0] argmax_output;  
    wire [3:0] current_state;
    wire [3:0] next_state;

	 
    // Clock divider instance
    clock_divider clk_div (
         .clk_in(CLOCK_50),
         .clk_out(clk_slow),
         .DIVISOR(32'd10)
    );

    wire [3:0] image_led_control;  // From image_memory
    assign LEDR[8:5] = image_led_control;  // Example of forwarding image memory control to LEDs
	  
    
    // Control signal assignments
    assign on = SW[0];         // Drawing grid enable
    assign draw = SW[1];      // Turn on to start drawing
    assign start = SW[2];    // Press to start (high)
    assign resetn = ~SW[9];    // ON to stop reset

    // Debug LEDs
    assign LEDR[9] = start;
    assign LEDR[3:0] = current_state;


    // Double check that signals match properly
    mnist_drawing_grid drawing_grid (
        .CLOCK_50(CLOCK_50),
        .reset(resetn),
        // .PS2_CLK(PS2_CLK),
        // .PS2_DAT(PS2_DAT),
        .KEY(KEY),
        .draw(draw),
        .on(on),
        .read_addr(image_read_addr),    
        .data_out(image_data_out),      
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK),
        .HEX0(HEX2),
        .HEX1(HEX3),
        .HEX2(HEX4),
        .HEX3(HEX5),
		.led_control(image_led_control)
    );

	 
	 
/// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    // Double check this module, and its submodules align with previous implementation (no_vga)
    // Neural network instance
    neural_network nn (
        .clk(clk_slow),
        .resetn(resetn),
        .start(start),

        .image_read_addr(image_read_addr),
        .image_data_out(image_data_out),

        .done(done),

        .current_state(current_state),
        .next_state(next_state),
        .argmax_output(argmax_output)
    );
/// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
	 
	 
	 
    // Seven segment decoder logic
    reg [6:0] seg7_display;
    assign HEX0 = seg7_display;
    // Changed to CLOCK_50 from *
    // Safer to update on internal clock_edge
    always @(posedge CLOCK_50 or posedge resetn) begin
        if (resetn) begin
            seg7_display = 7'b1111111;
        end else begin
            case (argmax_output)
                4'd0: seg7_display = 7'b1000000;
                4'd1: seg7_display = 7'b1111001;
                4'd2: seg7_display = 7'b0100100;
                4'd3: seg7_display = 7'b0110000;
                4'd4: seg7_display = 7'b0011001;
                4'd5: seg7_display = 7'b0010010;
                4'd6: seg7_display = 7'b0000010;
                4'd7: seg7_display = 7'b1111000;
                4'd8: seg7_display = 7'b0000000;
                4'd9: seg7_display = 7'b0010000;
                4'd10: seg7_display = 7'b0111111;
                default: seg7_display = 7'b1111111;
            endcase
        end
    end

    // Turn off unused display
    assign HEX1 = 7'b1111111;

endmodule