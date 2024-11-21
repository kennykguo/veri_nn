module vga_demo(
    input CLOCK_50,    // 50 MHz clock input
    input [9:0] SW,    // Switch inputs
    input [3:0] KEY,   // Key (button) inputs
    output [7:0] VGA_R, VGA_G, VGA_B, // VGA color output (Red, Green, Blue)
    output VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK, // VGA sync and control signals
    output [6:0] HEX0, HEX1, HEX2, HEX3, // 7-segment display outputs for coordinates
    output [9:0] LEDR // LED outputs for debugging and showing data
);
    
    // Grid constants for grid size, pixel size, and offsets for drawing
    parameter GRID_SIZE = 28;      // Number of cells in the grid (28x28)
    parameter PIXEL_SIZE = 4;      // Size of each pixel (4x4)
    parameter GRID_OFFSET_X = 10;  // Horizontal offset for grid drawing
    parameter GRID_OFFSET_Y = 10;  // Vertical offset for grid drawing
    
    // Memory array to store the state of each pixel (whether it is on or off)
    reg [0:0] pixel_memory [0:783];  // 784 pixels, 1-bit per pixel (28x28 grid)
    
    // Registers to track the current cursor position
    reg [4:0] current_x; // Horizontal cursor position (0 to 27)
    reg [4:0] current_y; // Vertical cursor position (0 to 27)
    
    // Button press detection logic for moving the cursor
    reg [3:0] key_prev;  // Stores previous state of buttons
    wire [3:0] key_pressed = ~KEY & ~key_prev;  // Detects which button is pressed

    // Movement control, with a delay to make movement not too fast
    reg [19:0] move_delay; // Counter for movement delay
    parameter DELAY_MAX = 20'd100000; // Maximum delay value for key press debounce
    
    // VGA signals
    wire [7:0] x;  // X-coordinate for VGA output (should hold direct pixel location on the monitor)
    wire [6:0] y;  // Y-coordinate for VGA output (should hold direct pixel location on the monitor)
    wire [2:0] colour_out; // 3-bit color output (RGB)

    // Drawing control signals and pixel coordinate registers
    reg plot;  // Signal to indicate if a pixel is being drawn
    reg [7:0] draw_x;  // X-coordinate for drawing
    reg [6:0] draw_y;  // Y-coordinate for drawing
    
    // Offset for drawing individual pixels - 4 x 4 drawing tool
    reg [1:0] pixel_x_offset; // Placeholder variables for looping (stores current offset)
    reg [1:0] pixel_y_offset; 
    
    // State control for pixel drawing
    reg [2:0] pixel_draw_state;  // 3-bit state for pixel drawing process
    reg [1:0] draw_pixel_x;     // X-offset for pixel drawing
    reg [1:0] draw_pixel_y;     // Y-offset for pixel drawing
    
    // State machine for grid background drawing
    reg [2:0] draw_state;   // State for the grid drawing process
    reg [4:0] grid_x, grid_y;  // Grid coordinates for drawing
    
    // Debugging output: show current cursor position on LEDs
    assign LEDR[9] = SW[9];  // Show switch 9 state on LED 9
    assign LEDR[8] = SW[1];  // Show switch 1 state on LED 8
    assign LEDR[4:0] = current_x[4:0];  // Show cursor X-coordinate on LED 4-0
    // 7-segment display modules to show the cursor coordinates (X and Y)
    hex_display hex0(current_x[3:0], HEX0);  // Display lower 4 bits of current_x
    hex_display hex1({3'b000, current_x[4]}, HEX1);  // Display upper bit of current_x
    hex_display hex2(current_y[3:0], HEX2);  // Display lower 4 bits of current_y
    hex_display hex3({3'b000, current_y[4]}, HEX3);  // Display upper bit of current_y
    
	 
	 
    // Initialize memory and registers
    integer i;
    initial begin
        // Initialize all pixels to 0 (off) at the start
        for(i = 0; i < 784; i = i + 1) begin
            pixel_memory[i] <= 1'b0;
        end
        // Start in the middle of the grid
		  
        current_x <= 5'd14;  // Middle X position
        current_y <= 5'd14;  // Middle Y position
		  
        key_prev <= 4'b1111;  // No key pressed initially
        move_delay <= 20'd0;  // No delay initially
        draw_state <= 3'b000;  // Start with state 0 (initialize grid)
        draw_x <= GRID_OFFSET_X;  // Set initial X draw position
        draw_y <= GRID_OFFSET_Y;  // Set initial Y draw position
        pixel_x_offset <= 2'b00;  // Start with pixel offset 0 (offset from drawing pixel)
        pixel_y_offset <= 2'b00;  // Start with pixel offset 0
        pixel_draw_state <= 3'b000;  // Idle state for pixel drawing
        plot <= 1'b0;  // No pixel to plot initially
    end
    
	 
	 // Parameters for draw_state
	parameter DRAW_STATE_INIT = 3'b000;  // Grid initialization state
	parameter DRAW_STATE_DRAW = 3'b001;  // Drawing the grid state
	parameter DRAW_STATE_MAIN_OP = 3'b010;  // Main operation state (cursor movement, pixel drawing)

	// Parameters for pixel_draw_state
	parameter PIXEL_DRAW_IDLE = 3'b000;  // Idle state (waiting to draw)
	parameter PIXEL_DRAW_DRAW = 3'b001;  // Drawing pixel state
	parameter PIXEL_DRAW_UPDATE = 3'b010;  // Updating pixel coordinates state

	
	 // Pixel drawing FSM
    always @(posedge CLOCK_50) begin
		 case(draw_state)
			  DRAW_STATE_INIT: begin  // Initialize grid drawing state
					draw_x <= GRID_OFFSET_X;  // Reset drawing X position (CURRENT DRAWING POSITION)
					draw_y <= GRID_OFFSET_Y;  // Reset drawing Y position (CURRENT DRAWING POSITION)
					grid_x <= 5'b00000;  // Reset grid X position to 0 (position in 28 x 28 grid)
					grid_y <= 5'b00000;  // Reset grid Y position to 0
					pixel_x_offset <= 2'b00;  // Reset pixel X offset to 0
					pixel_y_offset <= 2'b00;  // Reset pixel Y offset to 0
					draw_state <= DRAW_STATE_DRAW;  // Transition to grid drawing state
					plot <= 1'b1;  // Enable pixel plotting
			  end
			  
			  DRAW_STATE_DRAW: begin  // Draw the initial grid (loop through the entire grid)
					// Handle pixel X offset and draw pixels row by row
					if (pixel_x_offset == 2'b11) begin
						 pixel_x_offset <= 2'b00; // Reset the row
						 if (pixel_y_offset == 2'b11) begin
							  pixel_y_offset <= 2'b00; // Reset the col
							  draw_x <= draw_x + PIXEL_SIZE; // Increment to the next row
							  // If we reach the end of a row, move to the next row
							  if (draw_x >= (GRID_OFFSET_X + GRID_SIZE * PIXEL_SIZE - PIXEL_SIZE)) begin
									draw_x <= GRID_OFFSET_X;
									draw_y <= draw_y + PIXEL_SIZE;
							  end
						 end else begin
							  pixel_y_offset <= pixel_y_offset + 1'b1;
						 end
					end else begin
						 pixel_x_offset <= pixel_x_offset + 1'b1;
					end
					
					// If all grid pixels are drawn, transition to next state
					if (draw_y >= (GRID_OFFSET_Y + GRID_SIZE * PIXEL_SIZE - PIXEL_SIZE) && 
						 pixel_y_offset == 2'b11 && pixel_x_offset == 2'b11) begin
						 draw_state <= DRAW_STATE_MAIN_OP;  // Transition to main operation state
						 pixel_draw_state <= PIXEL_DRAW_IDLE;  // Idle state for pixel drawing
						 plot <= 1'b0;  // Disable pixel plotting
					end
			  end
			  
			  
			  
			  DRAW_STATE_MAIN_OP: begin  // Main operation state (handling movement and drawing)
					// Movement control, drawing logic, etc.
			  end
		 endcase
		 
		 

		 case(pixel_draw_state)
			  PIXEL_DRAW_IDLE: begin  // Idle state (wait to start drawing)
					draw_pixel_x <= 2'b00;  // Start at the first pixel in X direction
					draw_pixel_y <= 2'b00;  // Start at the first pixel in Y direction
					plot <= 1'b0;  // No pixel is being drawn yet
					if (SW[1]) pixel_draw_state <= PIXEL_DRAW_DRAW;  // Transition to drawing state when switch 1 is pressed
			  end
			  
			  PIXEL_DRAW_DRAW: begin  // Drawing state (drawing a pixel)
					plot <= 1'b1;  // Enable pixel plotting
					draw_x <= GRID_OFFSET_X + (current_x * PIXEL_SIZE) + draw_pixel_x;  // Set X position for drawing
					draw_y <= GRID_OFFSET_Y + (current_y * PIXEL_SIZE) + draw_pixel_y;  // Set Y position for drawing
					pixel_draw_state <= PIXEL_DRAW_UPDATE;  // Move to next state for updating the pixel coordinates
			  end
			  
			  PIXEL_DRAW_UPDATE: begin  // Update pixel coordinates
					plot <= 1'b0;  // Disable pixel plotting
					if (draw_pixel_x == 2'b11) begin
						 draw_pixel_x <= 2'b00;  // Reset X offset
						 if (draw_pixel_y == 2'b11) begin
							  pixel_draw_state <= PIXEL_DRAW_IDLE;  // Return to idle state after drawing all pixels
							  pixel_memory[current_y * GRID_SIZE + current_x] <= 1'b1;  // Mark the pixel as drawn
						 end else begin
							  draw_pixel_y <= draw_pixel_y + 1'b1;  // Move to next Y pixel
							  pixel_draw_state <= PIXEL_DRAW_DRAW;  // Continue drawing
						 end
					end else begin
						 draw_pixel_x <= draw_pixel_x + 1'b1;  // Move to next X pixel
						 pixel_draw_state <= PIXEL_DRAW_DRAW;  // Continue drawing
					end
			  end
		 endcase
	end

    
    // Color output logic for the VGA
    assign colour_out = (draw_state == 3'b001) ? 3'b111 : // White color for grid
                       (pixel_draw_state == 3'b001 || pixel_draw_state == 3'b010) ? 3'b000 : // Black color for drawing
                       // Check if the current pixel is within the grid and whether it's the cursor or a drawn pixel
                       ((x >= GRID_OFFSET_X && x < (GRID_OFFSET_X + GRID_SIZE * PIXEL_SIZE) &&
                         y >= GRID_OFFSET_Y && y < (GRID_OFFSET_Y + GRID_SIZE * PIXEL_SIZE)) ? 
                        ((((x - GRID_OFFSET_X) / PIXEL_SIZE) == current_x && 
                          ((y - GRID_OFFSET_Y) / PIXEL_SIZE) == current_y) ? 3'b100 : // Red for cursor
                         (pixel_memory[((y - GRID_OFFSET_Y) / PIXEL_SIZE) * GRID_SIZE + 
                                     ((x - GRID_OFFSET_X) / PIXEL_SIZE)] ? 3'b000 : 3'b111)) : // Black or White for background
                        3'b000);  // Default to black background
    
    // VGA controller to handle the VGA signal generation
    vga_adapter VGA (
        .resetn(1'b1),          // VGA reset signal (always active)
        .clock(CLOCK_50),       // 50 MHz clock input
        .colour(colour_out),    // VGA color input
        .x(draw_state == 3'b001 ? draw_x + pixel_x_offset :
           (pixel_draw_state == 3'b001 || pixel_draw_state == 3'b010) ? draw_x : x), // Adjust X position
        .y(draw_state == 3'b001 ? draw_y + pixel_y_offset :
           (pixel_draw_state == 3'b001 || pixel_draw_state == 3'b010) ? draw_y : y), // Adjust Y position
        .plot(draw_state == 3'b001 || pixel_draw_state == 3'b001), // Indicate when to plot the pixel
        .VGA_R(VGA_R),          // VGA red color output
        .VGA_G(VGA_G),          // VGA green color output
        .VGA_B(VGA_B),          // VGA blue color output
        .VGA_HS(VGA_HS),        // VGA horizontal sync output
        .VGA_VS(VGA_VS),        // VGA vertical sync output
        .VGA_BLANK_N(VGA_BLANK_N), // VGA blank signal
        .VGA_SYNC_N(VGA_SYNC_N),   // VGA sync signal
        .VGA_CLK(VGA_CLK)          // VGA clock output
    );
    
    // VGA controller parameters
    defparam VGA.RESOLUTION = "160x120";  // Set VGA resolution
    defparam VGA.MONOCHROME = "FALSE";   // Enable color output (not monochrome)
    defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;  // Use 1 bit per color channel
    defparam VGA.BACKGROUND_IMAGE = "black.mif";  // Use a black background image
    
endmodule

// Hex display module (no changes needed here)
module hex_display(
    input [3:0] IN,    // 4-bit input to be displayed
    output reg [6:0] OUT  // 7-segment output display
);
    always @(*)
        case (IN)
            4'h0: OUT = 7'b1000000;  // 0
            4'h1: OUT = 7'b1111001;  // 1
            4'h2: OUT = 7'b0100100;  // 2
            4'h3: OUT = 7'b0110000;  // 3
            4'h4: OUT = 7'b0011001;  // 4
            4'h5: OUT = 7'b0010010;  // 5
            4'h6: OUT = 7'b0000010;  // 6
            4'h7: OUT = 7'b1111000;  // 7
            4'h8: OUT = 7'b0000000;  // 8
            4'h9: OUT = 7'b0010000;  // 9
            4'hA: OUT = 7'b0001000;  // A
            4'hB: OUT = 7'b0000011;  // B
            4'hC: OUT = 7'b1000110;  // C
            4'hD: OUT = 7'b0100001;  // D
            4'hE: OUT = 7'b0000110;  // E
            4'hF: OUT = 7'b0001110;  // F
            default: OUT = 7'b1111111; // Error display (all segments on)
        endcase
endmodule
