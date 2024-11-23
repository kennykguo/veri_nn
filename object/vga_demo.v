module vga_demo(
    input CLOCK_50,    
    input [7:0] SW,
    input [3:0] KEY,
    input ps2_clk,     // PS/2 clock input
    input ps2_data,    // PS/2 data input
    output [6:0] HEX3, HEX2, HEX1, HEX0,
    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output VGA_HS,
    output VGA_VS,
    output VGA_BLANK_N,
    output VGA_SYNC_N,
    output VGA_CLK
);
    wire [9:0] mouse_x;  // Mouse X position
    wire [9:0] mouse_y;  // Mouse Y position
    wire left_button;     // Left button state
    wire right_button;    // Right button state

    // PS/2 mouse module instance
    ps2_mouse mouse (
        .clk(CLOCK_50),
        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data),
        .mouse_x(mouse_x),
        .mouse_y(mouse_y),
        .left_button(left_button),
        .right_button(right_button)
    );

    // Use mouse coordinates to draw the object on the screen
    reg [7:0] VGA_X;
    reg [6:0] VGA_Y;
    reg [2:0] VGA_COLOR;

    always @(posedge CLOCK_50) begin
        VGA_X <= mouse_x[7:0];  // Use lower 8 bits for X
        VGA_Y <= mouse_y[6:0];  // Use lower 7 bits for Y
		  // Set cursor color to black (0)
		 VGA_COLOR <= 3'b000;  // Black for the cursor
		 
		 // We will use the VGA_X and VGA_Y values to plot the cursor as a black dot
		 if (VGA_X == mouse_x[7:0] && VGA_Y == mouse_y[6:0]) begin
			  // If the current pixel is at the mouse position, draw the cursor (black dot)
			  VGA_COLOR <= 3'b000;  // Black dot color
		 end else begin
			  // Otherwise, keep the background color (white)
			  VGA_COLOR <= 3'b111;  // White background color
		 end
    end

    // VGA Adapter instance for drawing the object
    vga_adapter VGA (
        .resetn(KEY[0]),
        .clock(CLOCK_50),
        .colour(VGA_COLOR),
        .x(VGA_X),
        .y(VGA_Y),
        .plot(~KEY[3]),
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
    defparam VGA.BACKGROUND_IMAGE = "test4.mif";  // Optional background image

    // Assign mouse coordinates to HEX displays
    assign HEX0 = mouse_x[3:0];  // Lower 4 bits of mouse_x on HEX0
    assign HEX1 = mouse_x[7:4];  // Upper 4 bits of mouse_x on HEX1
    assign HEX2 = mouse_y[3:0];  // Lower 4 bits of mouse_y on HEX2
    assign HEX3 = mouse_y[7:4];  // Upper 4 bits of mouse_y on HEX3

endmodule

module ps2_mouse(
    input clk,            // FPGA clock
    input ps2_clk,        // PS/2 clock
    input ps2_data,       // PS/2 data line
    output reg [9:0] mouse_x,   // X position of mouse
    output reg [9:0] mouse_y,   // Y position of mouse
    output reg left_button,     // Left button press state
    output reg right_button     // Right button press state
);
    reg [3:0] bit_count;  // Bit counter to keep track of bits
    reg [7:0] byte_data;  // Data byte from mouse
    reg [15:0] shift_reg; // Shift register for data
    reg last_clk;         // PS/2 clock signal for edge detection

    reg [2:0] packet_count;  // Keep track of the 3-byte packet

    // Mouse state registers
    reg signed [8:0] x_movement; // X axis movement (signed)
    reg signed [8:0] y_movement; // Y axis movement (signed)

    // Always block to handle clock edge and PS/2 data capture
    always @(posedge clk) begin
        if (ps2_clk == 1'b0 && last_clk == 1'b1) begin
            // Shift in the data from PS/2 mouse
            shift_reg <= {ps2_data, shift_reg[15:1]};

            // Increment bit_count, ensuring it's only done once per shift
            if (bit_count < 8) begin
                bit_count <= bit_count + 1;  // Increment bit_count
            end
        end
        last_clk <= ps2_clk;  // Store the previous clock state

        // Process the received byte when all 8 bits are shifted in
        if (bit_count == 8) begin
            byte_data <= shift_reg[7:0];  // Capture the byte
            bit_count <= 0;  // Reset bit_count after processing one byte

            case (packet_count)
                0: begin
                    left_button <= byte_data[0];    // Left button state
                    right_button <= byte_data[1];   // Right button state
                end
                1: begin
                    x_movement <= byte_data;  // X axis movement (signed)
                end
                2: begin
                    y_movement <= byte_data;  // Y axis movement (signed)
                    // Update mouse position (avoid truncation)
                    mouse_x <= mouse_x + x_movement;
                    mouse_y <= mouse_y + y_movement;
                end
            endcase

            // Move to the next packet byte
            packet_count <= packet_count + 1; 

            // Reset packet counter after processing 3 bytes
            if (packet_count == 3) begin
                packet_count <= 0;
            end
        end
    end
endmodule





