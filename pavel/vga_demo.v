module vga_demo(
    input CLOCK_50,        // 50 MHz clock input
    input [9:0] SW,        // Switch inputs
    input [3:0] KEY,       // Key (button) inputs
    output [7:0] VGA_R, VGA_G, VGA_B, // VGA color output (Red, Green, Blue)
    output VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK, // VGA sync and control signals
    output [6:0] HEX0, HEX1, HEX2, HEX3, // 7-segment display outputs for coordinates
    output [9:0] LEDR       // LED outputs for debugging and showing data
);

    // Parameters
    parameter GRID_SIZE = 28;          // Logical grid size (28x28)
    parameter CHUNK_SIZE = 4;          // Physical pixel chunk size (4x4)
    parameter PHYSICAL_SIZE = GRID_SIZE * CHUNK_SIZE; // Total physical grid size (112x112)
    parameter GRID_OFFSET_X = 10;      // Horizontal offset for the grid on VGA
    parameter GRID_OFFSET_Y = 10;      // Vertical offset for the grid on VGA

    // Cursor and memory
    reg [4:0] current_x;              // Cursor X position (logical grid)
    reg [4:0] current_y;              // Cursor Y position (logical grid)
    reg [0:0] pixel_memory [0:783];   // Memory for 28x28 logical grid (1-bit per logical pixel)
    reg draw_enable;                  // Indicates whether to draw (SW[0] enabled)

    // Button press detection
    reg [3:0] key_prev;
    wire [3:0] key_pressed = ~KEY & ~key_prev;

    // VGA control
    wire [9:0] vga_x;
    wire [9:0] vga_y;
    reg [2:0] colour_out;
    reg plot;

    // Debugging and output
    assign LEDR[4:0] = current_x[4:0];  // Display cursor X on LEDs
    assign LEDR[9] = SW[0];            // Drawing enable indicator

    // 7-segment display for cursor coordinates
    hex_display hex0(current_x[3:0], HEX0);
    hex_display hex1({3'b000, current_x[4]}, HEX1);
    hex_display hex2(current_y[3:0], HEX2);
    hex_display hex3({3'b000, current_y[4]}, HEX3);

    // Initialize memory and cursor position
    integer i;
    initial begin
        // Initialize all pixels to 0 (off) at the start
        for(i = 0; i < 784; i = i + 1) begin
            pixel_memory[i] <= 1'b0;
        end
        // Start in the middle of the logical grid
        current_x <= 5'd14;  // Middle X position (logical grid)
        current_y <= 5'd14;  // Middle Y position (logical grid)

        key_prev <= 4'b1111;  // No key pressed initially
        draw_enable <= 0;     // No drawing enabled initially
    end

    // VGA controller logic
    always @(posedge CLOCK_50) begin
        // Handle button press for drawing enable
        if (~SW[0]) begin
            draw_enable <= 1;  // Enable drawing when SW[0] is low
        end else begin
            draw_enable <= 0;  // Disable drawing when SW[0] is high
        end

        // Update pixel memory based on drawing enable and cursor position
        if (draw_enable) begin
            pixel_memory[current_y * GRID_SIZE + current_x] <= 1'b1;
        end
    end

    // VGA pixel mapping: Scale logical 28x28 grid to physical 112x112
    always @(posedge CLOCK_50) begin
        // Mapping (logical coordinates) to physical coordinates on VGA screen
        // Logical (current_x, current_y) -> Physical (vga_x, vga_y)
        
        if (vga_x >= GRID_OFFSET_X && vga_x < GRID_OFFSET_X + PHYSICAL_SIZE && 
            vga_y >= GRID_OFFSET_Y && vga_y < GRID_OFFSET_Y + PHYSICAL_SIZE) begin

            // Determine the logical (28x28) grid coordinates for the current pixel
            integer logical_x = (vga_x - GRID_OFFSET_X) / CHUNK_SIZE;
            integer logical_y = (vga_y - GRID_OFFSET_Y) / CHUNK_SIZE;

            // Check if this pixel belongs to the drawn logical pixel
            if (pixel_memory[logical_y * GRID_SIZE + logical_x] == 1'b1) begin
                colour_out = 3'b111; // White color
            end else begin
                colour_out = 3'b000; // Black color
            end
        end else begin
            colour_out = 3'b000; // Black color for outside the grid
        end
    end

    // VGA display logic
    vga_adapter VGA (
        .resetn(1'b1),
        .clock(CLOCK_50),
        .colour(colour_out),
        .x(vga_x),
        .y(vga_y),
        .plot(plot),
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
    defparam VGA.BACKGROUND_IMAGE = "black.mif";  // Default background image (black)

endmodule

// 7-segment display decoder
module hex_display(
    input [3:0] IN,
    output reg [6:0] OUT
);
    always @(*)
        case (IN)
            4'h0: OUT = 7'b1000000;
            4'h1: OUT = 7'b1111001;
            4'h2: OUT = 7'b0100100;
            4'h3: OUT = 7'b0110000;
            4'h4: OUT = 7'b0011001;
            4'h5: OUT = 7'b0010010;
            4'h6: OUT = 7'b0000010;
            4'h7: OUT = 7'b1111000;
            4'h8: OUT = 7'b0000000;
            4'h9: OUT = 7'b0010000;
            4'hA: OUT = 7'b0001000;
            4'hB: OUT = 7'b0000011;
            4'hC: OUT = 7'b1000110;
            4'hD: OUT = 7'b0100001;
            4'hE: OUT = 7'b0000110;
            4'hF: OUT = 7'b0001110;
            default: OUT = 7'b1111111;
        endcase
endmodule
