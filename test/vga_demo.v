module vga_demo(
    input CLOCK_50,
    input [3:0] KEY,
    input PS2_CLK,     // PS/2 clock input
    input PS2_DAT,     // PS/2 data input
    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output VGA_HS,
    output VGA_VS,
    output VGA_BLANK_N,
    output VGA_SYNC_N,
    output VGA_CLK,
    output [6:0] HEX0, // Display for mouse X (lower 4 bits)
    output [6:0] HEX1, // Display for mouse X (upper 4 bits)
    output [6:0] HEX2, // Display for mouse Y (lower 4 bits)
    output [6:0] HEX3  // Display for mouse Y (upper 4 bits)
);

    // Mouse data signals
    wire [9:0] mouse_x;
    wire [9:0] mouse_y;
    wire debug_signal;  // Debug signal to track mouse movements
    wire left_button;   // Left button signal

    // Instantiate PS/2 mouse module
    ps2_mouse mouse (
        .clk(CLOCK_50),
        .PS2_CLK(PS2_CLK),
        .PS2_DAT(PS2_DAT),
        .mouse_x(mouse_x),
        .mouse_y(mouse_y),
        .debug(debug_signal),
        .left_button(left_button)  // Pass left_button signal
    );

    // VGA signals
    reg [2:0] VGA_COLOR;
    wire [7:0] VGA_X;
    wire [6:0] VGA_Y;

    // Cursor size (5x5 block)
    localparam CURSOR_SIZE = 1; // 1x1 cursor

    // Cursor drawing logic
    always @(*) begin
        // Check if the current pixel is within the cursor region
        if (VGA_X >= (mouse_x[7:0] - CURSOR_SIZE/2) && VGA_X < (mouse_x[7:0] + CURSOR_SIZE/2) &&
            VGA_Y >= (mouse_y[6:0] - CURSOR_SIZE/2) && VGA_Y < (mouse_y[6:0] + CURSOR_SIZE/2)) 
        begin
            VGA_COLOR = 3'b000; // Black cursor
        end
        else if (left_button) begin
            // Draw a 1x1 pixel at the mouse position if the left button is pressed (white)
            VGA_COLOR = 3'b111; // White color for drawing
        end
        else
            VGA_COLOR = 3'b111; // White background
    end

    // VGA Adapter instance
    vga_adapter VGA (
        .resetn(KEY[0]),
        .clock(CLOCK_50),
        .colour(VGA_COLOR),
        .x(VGA_X),
        .y(VGA_Y),
        .plot(1'b1), // Always plotting
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK)
    );
    defparam VGA.RESOLUTION = "160x120";
    defparam VGA.MONOCHROME = "FALSE";
    defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
    defparam VGA.BACKGROUND_IMAGE = "test4.mif";  // Background image

    // Hexadecimal display logic for mouse X and Y
    Hexadecimal_To_Seven_Segment SegmentX0 (
        .hex_number(mouse_x[3:0]), // lower 4 bits of x coord
        .seven_seg_display(HEX0)
    );
    Hexadecimal_To_Seven_Segment SegmentX1 (
        .hex_number(mouse_x[7:4]), // Upper 4 bits of x coord
        .seven_seg_display(HEX1)
    );
    Hexadecimal_To_Seven_Segment SegmentY0 (
        .hex_number(mouse_y[3:0]), 
        .seven_seg_display(HEX2)
    );
    Hexadecimal_To_Seven_Segment SegmentY1 (
        .hex_number(mouse_y[7:4]),
        .seven_seg_display(HEX3)
    );

    // Display debug signal to check movement in waveform
    assign debug_signal = debug_signal; // Output debug signal for monitoring

endmodule


module ps2_mouse(
    input clk,
    input PS2_CLK,
    input PS2_DAT,
    output reg [9:0] mouse_x = 10'd80,  // Default X position
    output reg [9:0] mouse_y = 10'd60,   // Default Y position
    output reg debug = 0,                 // Debug signal to track movement
    output reg left_button = 0           // Left mouse button state
);
    reg [3:0] bit_count = 0;
    reg [7:0] byte_data = 0;
    reg [1:0] packet_count = 0;
    reg [8:0] x_movement = 0;
    reg [8:0] y_movement = 0;
    reg last_clk = 1;

    // Simulate mouse movement for testing purposes
    reg [8:0] simulated_x = 0;
    reg [8:0] simulated_y = 0;

    always @(posedge clk) begin
        if (simulated_x < 10) simulated_x <= simulated_x + 1;  // Increase X position for movement
        if (simulated_y < 10) simulated_y <= simulated_y + 1;  // Increase Y position for movement

        if (PS2_CLK == 0 && last_clk == 1) begin
            byte_data <= {PS2_DAT, byte_data[7:1]};
            bit_count <= bit_count + 1;
        end
        last_clk <= PS2_CLK;

        if (bit_count == 8) begin
            bit_count <= 0;
            case (packet_count)
                0: left_button <= byte_data[0]; // Left button state is the least significant bit
                1: x_movement <= simulated_x; // Use simulated X movement
                2: begin
                    y_movement <= simulated_y; // Use simulated Y movement
                    mouse_x <= mouse_x + x_movement;
                    mouse_y <= mouse_y - y_movement; // VGA origin is top-left, so subtract Y

                    // Debugging: If mouse_x and mouse_y change, toggle the debug signal
                    if (x_movement != 0 || y_movement != 0) begin
                        debug <= 1;  // Trigger debug signal when movement is detected
                    end else begin
                        debug <= 0;  // Reset debug signal if no movement
                    end
                end
            endcase
            packet_count <= packet_count + 1;
            if (packet_count == 2)
                packet_count <= 0;
        end
    end
endmodule
