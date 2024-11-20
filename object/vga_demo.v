module vga_demo(
    input CLOCK_50,    
    input [9:0] SW,
    input [3:0] KEY,
    output [6:0] HEX3, HEX2, HEX1, HEX0,
    output [7:0] VGA_R, VGA_G, VGA_B,
    output VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK
);
    
    // Current cursor position
    wire [4:0] cursor_x;
    wire [4:0] cursor_y;
    wire [15:0] mem_address;
    wire [31:0] pixel_data;
    
    // Grid constants (28x28)
    parameter GRID_SIZE = 28;
    parameter PIXEL_SIZE = 4; // Each grid pixel is 4x4 VGA pixels
    parameter GRID_OFFSET_X = 16; // Center the grid
    parameter GRID_OFFSET_Y = 12;
    
    // Cursor position registers
    reg [4:0] current_x = 5'd14; // Start in middle
    reg [4:0] current_y = 5'd14;
    
    // VGA coordinates
    wire [7:0] vga_x;
    wire [6:0] vga_y;
    wire [2:0] color;
    
    // Movement control
    reg [19:0] move_delay = 20'd0;
    parameter DELAY_MAX = 20'd500000; // Debounce delay
    
    // Calculate memory address from cursor position
    assign mem_address = current_y * GRID_SIZE + current_x;
    
    // Image memory instantiation
    image_memory img_mem (
        .address(mem_address),
        .data_out(pixel_data)
    );
    
    // Position display on hex
    hex7seg H3 ({3'b000, current_x[4]}, HEX3);
    hex7seg H2 (current_x[3:0], HEX2);
    hex7seg H1 ({3'b000, current_y[4]}, HEX1);
    hex7seg H0 (current_y[3:0], HEX0);
    
    // Movement and drawing logic
    always @(posedge CLOCK_50) begin
        if (!KEY[0]) begin // Reset
            current_x <= 5'd14;
            current_y <= 5'd14;
            move_delay <= 20'd0;
        end
        else begin
            if (move_delay == DELAY_MAX) begin
                move_delay <= 20'd0;
                
                // Movement controls
                if (!KEY[3] && current_x < (GRID_SIZE-1)) current_x <= current_x + 1; // Right
                if (!KEY[2] && current_x > 0) current_x <= current_x - 1; // Left
                if (!KEY[1] && current_y > 0) current_y <= current_y - 1; // Up
                if (!KEY[0] && current_y < (GRID_SIZE-1)) current_y <= current_y + 1; // Down
            end
            else
                move_delay <= move_delay + 1;
        end
    end
    
    // VGA coordinate calculation
    assign vga_x = GRID_OFFSET_X + (current_x * PIXEL_SIZE);
    assign vga_y = GRID_OFFSET_Y + (current_y * PIXEL_SIZE);
    
    // Color determination
    assign color = (SW[1]) ? 3'b111 : 3'b000; // White when drawing, black otherwise
    
    // VGA controller
    vga_adapter VGA (
        .resetn(KEY[0]),
        .clock(CLOCK_50),
        .colour(color),
        .x(vga_x),
        .y(vga_y),
        .plot(SW[1]),
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