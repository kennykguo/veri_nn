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
    reg [4:0] current_x; // Current horizontal cursor position (0 to 27 in the grid)
    reg [4:0] current_y; // Current vertical cursor position (0 to 27 in the grid)
    
    // Button press detection logic for moving the cursor
    reg [3:0] key_prev;  // Stores previous state of buttons
    wire [3:0] key_pressed = ~KEY & ~key_prev;  // Detects which button is pressed

    // Movement control, with a delay to make movement not too fast
    reg [19:0] move_delay; // Counter for movement delay
    parameter DELAY_MAX = 20'd100000; // Maximum delay value for key press debounce
    
    // VGA signals
    wire [7:0] temp_x;  // Temporary VGA X coordinate
    wire [6:0] temp_y;  // Temporary VGA Y coordinate
    wire [2:0] colour_out; // 3-bit color output (RGB)

    // Drawing control signals and pixel coordinate registers
    reg plot;  // Signal to indicate if a pixel is being drawn
    reg [7:0] current_draw_x;  // Current X-coordinate for drawing (goes into the vga)
    reg [6:0] current_draw_y;  // Current Y-coordinate for drawing (goes into the vga)
    
    // Offset for drawing individual pixels - 4 x 4 drawing tool
    reg [1:0] current_pixel_x_offset; // Current x offset in the grid
    reg [1:0] current_pixel_y_offset; // Current y offset in the grid
    
    // State control for pixel drawing
    reg [2:0] pixel_draw_state;  // 3-bit state for pixel drawing process
    reg [1:0] temp_draw_pixel_x;  // Temporary X-offset for pixel drawing
    reg [1:0] temp_draw_pixel_y;  // Temporary Y-offset for pixel drawing
    
    // State machine for grid background drawing
    reg [2:0] draw_state;   // State for the grid drawing process
    reg [4:0] current_grid_x, current_grid_y;  // Current position in the grid
    
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
        current_draw_x <= GRID_OFFSET_X;  // Set initial X draw position
        current_draw_y <= GRID_OFFSET_Y;  // Set initial Y draw position
        current_pixel_x_offset <= 2'b00;  // Start with pixel offset 0
        current_pixel_y_offset <= 2'b00;  // Start with pixel offset 0
        pixel_draw_state <= 3'b000;  // Idle state for pixel drawing
        plot <= 1'b0;  // No pixel to plot initially
    end
    
    // Parameters for draw_state
    parameter DRAW_STATE_INIT = 3'b000;  // Grid initialization state
    parameter DRAW_STATE_DRAW = 3'b001;  // Drawing the grid state
    parameter DRAW_STATE_MAIN_OP = 3'b010;  // Main operation state

    // Parameters for pixel_draw_state
    parameter PIXEL_DRAW_IDLE = 3'b000;  // Idle state (waiting to draw)
    parameter PIXEL_DRAW_DRAW = 3'b001;  // Drawing pixel state
    parameter PIXEL_DRAW_UPDATE = 3'b010;  // Updating pixel coordinates state

    // Pixel drawing FSM
    always @(posedge CLOCK_50) begin
        case(draw_state)
            DRAW_STATE_INIT: begin
                current_draw_x <= GRID_OFFSET_X;
                current_draw_y <= GRID_OFFSET_Y;
                current_grid_x <= 5'b00000;
                current_grid_y <= 5'b00000;
                current_pixel_x_offset <= 2'b00;
                current_pixel_y_offset <= 2'b00;
                draw_state <= DRAW_STATE_DRAW;
                plot <= 1'b1;
            end
            
            DRAW_STATE_DRAW: begin
                if (current_pixel_x_offset == 2'b11) begin
                    current_pixel_x_offset <= 2'b00;
                    if (current_pixel_y_offset == 2'b11) begin
                        current_pixel_y_offset <= 2'b00;
                        // Increment to the next pixel
                        current_draw_x <= current_draw_x + PIXEL_SIZE;
                        if (current_draw_x >= (GRID_OFFSET_X + GRID_SIZE * PIXEL_SIZE - PIXEL_SIZE)) begin
                            current_draw_x <= GRID_OFFSET_X;
                            current_draw_y <= current_draw_y + PIXEL_SIZE;
                        end
                    end else begin
                        current_pixel_y_offset <= current_pixel_y_offset + 1'b1;
                    end
                end else begin
                    current_pixel_x_offset <= current_pixel_x_offset + 1'b1;
                end
                
                if (current_draw_y >= (GRID_OFFSET_Y + GRID_SIZE * PIXEL_SIZE - PIXEL_SIZE) && 
                    current_pixel_y_offset == 2'b11 && current_pixel_x_offset == 2'b11) begin
                    draw_state <= DRAW_STATE_MAIN_OP;
                    pixel_draw_state <= PIXEL_DRAW_IDLE;
                    plot <= 1'b0;
                end
            end
            
            DRAW_STATE_MAIN_OP: begin
                // Movement control, drawing logic, etc.
            end
        endcase
        



        case(pixel_draw_state)
            PIXEL_DRAW_IDLE: begin
                temp_draw_pixel_x <= 2'b00;
                temp_draw_pixel_y <= 2'b00;
                plot <= 1'b0;
                if (SW[1]) pixel_draw_state <= PIXEL_DRAW_DRAW;
            end
            
            PIXEL_DRAW_DRAW: begin
                plot <= 1'b1;
                current_draw_x <= GRID_OFFSET_X + (current_x * PIXEL_SIZE) + temp_draw_pixel_x;
                current_draw_y <= GRID_OFFSET_Y + (current_y * PIXEL_SIZE) + temp_draw_pixel_y;
                pixel_draw_state <= PIXEL_DRAW_UPDATE;
            end
            
            PIXEL_DRAW_UPDATE: begin
                plot <= 1'b0;
                if (temp_draw_pixel_x == 2'b11) begin
                    temp_draw_pixel_x <= 2'b00;
                    if (temp_draw_pixel_y == 2'b11) begin
                        pixel_draw_state <= PIXEL_DRAW_IDLE;
                        pixel_memory[current_y * GRID_SIZE + current_x] <= 1'b1;
                    end else begin
                        temp_draw_pixel_y <= temp_draw_pixel_y + 1'b1;
                        pixel_draw_state <= PIXEL_DRAW_DRAW;
                    end
                end else begin
                    temp_draw_pixel_x <= temp_draw_pixel_x + 1'b1;
                    pixel_draw_state <= PIXEL_DRAW_DRAW;
                end
            end
        endcase
    end

    // Color output logic for the VGA
    assign colour_out = (draw_state == 3'b001) ? 3'b111 :
                       (pixel_draw_state == 3'b001 || pixel_draw_state == 3'b010) ? 3'b000 :
                       ((temp_x >= GRID_OFFSET_X && temp_x < (GRID_OFFSET_X + GRID_SIZE * PIXEL_SIZE) &&
                         temp_y >= GRID_OFFSET_Y && temp_y < (GRID_OFFSET_Y + GRID_SIZE * PIXEL_SIZE)) ? 
                        ((((temp_x - GRID_OFFSET_X) / PIXEL_SIZE) == current_x && 
                          ((temp_y - GRID_OFFSET_Y) / PIXEL_SIZE) == current_y) ? 3'b100 :
                         (pixel_memory[((temp_y - GRID_OFFSET_Y) / PIXEL_SIZE) * GRID_SIZE + 
                                     ((temp_x - GRID_OFFSET_X) / PIXEL_SIZE)] ? 3'b000 : 3'b111)) :
                        3'b000);
    
    // VGA controller
    vga_adapter VGA (
        .resetn(1'b1),
        .clock(CLOCK_50),
        .colour(colour_out),
        .x(draw_state == 3'b001 ? current_draw_x + current_pixel_x_offset :
           (pixel_draw_state == 3'b001 || pixel_draw_state == 3'b010) ? current_draw_x : temp_x),
        .y(draw_state == 3'b001 ? current_draw_y + current_pixel_y_offset :
           (pixel_draw_state == 3'b001 || pixel_draw_state == 3'b010) ? current_draw_y : temp_y),
        .plot(draw_state == 3'b001 || pixel_draw_state == 3'b001),
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
    defparam VGA.BACKGROUND_IMAGE = "black.mif";
    
endmodule

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