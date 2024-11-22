module vga_demo(
    input CLOCK_50,
    input [9:0] SW,
    input [3:0] KEY,
    output [7:0] VGA_R, VGA_G, VGA_B,
    output VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK,
    output [6:0] HEX0, HEX1, HEX2, HEX3,
    output [9:0] LEDR
);
    
    parameter GRID_SIZE = 28;
    parameter PIXEL_SIZE = 4;
    parameter GRID_OFFSET_X = 10;
    parameter GRID_OFFSET_Y = 10;
    
    reg [0:0] pixel_memory [0:783];  // 28x28 grid
    reg [4:0] current_x, current_y;
    reg [3:0] key_prev;
    wire [3:0] key_pressed = ~KEY & ~key_prev;
    reg [19:0] move_delay;
    parameter DELAY_MAX = 20'd100000;
    
    wire [7:0] vga_x;
    wire [6:0] vga_y;
    wire [2:0] color_out;
    
    // Debug outputs
    assign LEDR[9] = SW[9];
    assign LEDR[8] = SW[1];
    assign LEDR[4:0] = current_x[4:0];
    
    // Hex displays for coordinates
    hex_display hex0(current_x[3:0], HEX0);
    hex_display hex1({3'b000, current_x[4]}, HEX1);
    hex_display hex2(current_y[3:0], HEX2);
    hex_display hex3({3'b000, current_y[4]}, HEX3);
    
    integer i;
    initial begin
        for(i = 0; i < 784; i = i + 1) begin
            pixel_memory[i] <= 1'b0;
        end
        current_x <= 5'd14;
        current_y <= 5'd14;
        key_prev <= 4'b1111;
        move_delay <= 20'd0;
    end
    
    // Movement and drawing logic
    always @(posedge CLOCK_50) begin
        key_prev <= ~KEY;
        
        if(move_delay > 0)
            move_delay <= move_delay - 1;
            
        if(move_delay == 0) begin
            if(~KEY[0] && current_y < GRID_SIZE-1) begin  // Down
                current_y <= current_y + 1;
                move_delay <= DELAY_MAX;
            end
            else if(~KEY[1] && current_y > 0) begin  // Up
                current_y <= current_y - 1;
                move_delay <= DELAY_MAX;
            end
            else if(~KEY[2] && current_x < GRID_SIZE-1) begin  // Right
                current_x <= current_x + 1;
                move_delay <= DELAY_MAX;
            end
            else if(~KEY[3] && current_x > 0) begin  // Left
                current_x <= current_x - 1;
                move_delay <= DELAY_MAX;
            end
        end
        
        // Drawing logic
        if(SW[1])
            pixel_memory[current_y * GRID_SIZE + current_x] <= 1'b1;
    end
    
    // Calculate grid position from VGA coordinates
    wire [4:0] grid_x = (vga_x - GRID_OFFSET_X) / PIXEL_SIZE;
    wire [4:0] grid_y = (vga_y - GRID_OFFSET_Y) / PIXEL_SIZE;
    
    // Check if current VGA pixel is within grid boundaries
    wire in_grid = (vga_x >= GRID_OFFSET_X) && 
                  (vga_x < GRID_OFFSET_X + GRID_SIZE * PIXEL_SIZE) &&
                  (vga_y >= GRID_OFFSET_Y) && 
                  (vga_y < GRID_OFFSET_Y + GRID_SIZE * PIXEL_SIZE);
    
    // Determine if current pixel is cursor position
    wire is_cursor = in_grid && (grid_x == current_x) && (grid_y == current_y);
    
    // Get pixel state from memory
    wire pixel_state = in_grid ? pixel_memory[grid_y * GRID_SIZE + grid_x] : 1'b0;
    
    // Color assignment:
    // Red (3'b100) for cursor
    // Black (3'b000) for drawn pixels
    // White (3'b111) for background
    assign color_out = is_cursor ? 3'b100 :
                      (in_grid ? (pixel_state ? 3'b000 : 3'b111) : 3'b111);
    
    vga_adapter VGA(
        .resetn(1'b1),
        .clock(CLOCK_50),
        .colour(color_out),
        .x(vga_x),
        .y(vga_y),
        .plot(1'b1),
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