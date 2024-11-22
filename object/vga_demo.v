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
    parameter CELL_SIZE = 4;      
    parameter GRID_START_X = 10;  
    parameter GRID_START_Y = 10;  
    
    reg [0:0] grid_cells [0:783];  // 28x28 grid
    reg [4:0] cursor_pos_x;
    reg [4:0] cursor_pos_y;
    reg [3:0] prev_button_state;
    wire [3:0] button_pressed = ~KEY & ~prev_button_state;
    reg [24:0] move_cooldown;  // Increased size for slower movement
    parameter MOVE_DELAY_MAX = 25'd1000000; // Increased delay
    
    wire [7:0] vga_scan_x;
    wire [6:0] vga_scan_y;
    wire [2:0] pixel_color;
    
    // Debug outputs
    assign LEDR[9:5] = {SW[9], SW[1], cursor_pos_x[2:0]};
    assign LEDR[4:0] = cursor_pos_y[4:0];
    
    // Hex displays for coordinates
    hex_display hex0(cursor_pos_x[3:0], HEX0);
    hex_display hex1({3'b000, cursor_pos_x[4]}, HEX1);
    hex_display hex2(cursor_pos_y[3:0], HEX2);
    hex_display hex3({3'b000, cursor_pos_y[4]}, HEX3);
    
    integer i;
    initial begin
        for(i = 0; i < 784; i = i + 1) begin
            grid_cells[i] <= 1'b0;
        end
        cursor_pos_x <= 5'd14;
        cursor_pos_y <= 5'd14;
        prev_button_state <= 4'b1111;
        move_cooldown <= 25'd0;
    end
    
    // Movement and drawing logic
    always @(posedge CLOCK_50) begin
        prev_button_state <= ~KEY;
        
        // Movement cooldown
        if(move_cooldown > 0)
            move_cooldown <= move_cooldown - 1;
            
        // Process movement only when cooldown is zero
        if(move_cooldown == 0) begin
            if(~KEY[0] && cursor_pos_y < GRID_SIZE-1) begin  // Down
                cursor_pos_y <= cursor_pos_y + 1;
                move_cooldown <= MOVE_DELAY_MAX;
            end
            else if(~KEY[1] && cursor_pos_y > 0) begin  // Up
                cursor_pos_y <= cursor_pos_y - 1;
                move_cooldown <= MOVE_DELAY_MAX;
            end
            else if(~KEY[2] && cursor_pos_x < GRID_SIZE-1) begin  // Right
                cursor_pos_x <= cursor_pos_x + 1;
                move_cooldown <= MOVE_DELAY_MAX;
            end
            else if(~KEY[3] && cursor_pos_x > 0) begin  // Left
                cursor_pos_x <= cursor_pos_x - 1;
                move_cooldown <= MOVE_DELAY_MAX;
            end
        end
        
        // Drawing logic - Update grid cell when SW[1] is on
        if(SW[1])
            grid_cells[cursor_pos_y * GRID_SIZE + cursor_pos_x] <= 1'b1;
    end
    
    // VGA color output logic
    wire [9:0] relative_x = vga_scan_x - GRID_START_X;
    wire [9:0] relative_y = vga_scan_y - GRID_START_Y;
    wire [4:0] grid_x = relative_x / CELL_SIZE;
    wire [4:0] grid_y = relative_y / CELL_SIZE;
    
    wire in_grid_area = (vga_scan_x >= GRID_START_X) && 
                       (vga_scan_x < GRID_START_X + GRID_SIZE * CELL_SIZE) &&
                       (vga_scan_y >= GRID_START_Y) && 
                       (vga_scan_y < GRID_START_Y + GRID_SIZE * CELL_SIZE);
    
    wire is_cursor = (grid_x == cursor_pos_x) && (grid_y == cursor_pos_y);
    wire is_drawn = grid_cells[grid_y * GRID_SIZE + grid_x];
    
    // Color assignment logic
    assign pixel_color = in_grid_area ? 
                        (is_cursor ? 3'b100 :           // Red cursor
                         (is_drawn ? 3'b000 : 3'b111))  // Black pixels on white background
                        : 3'b111;                       // White background outside grid
    
    // VGA controller instantiation
    vga_adapter VGA (
        .resetn(1'b1),
        .clock(CLOCK_50),
        .colour(pixel_color),
        .x(vga_scan_x),
        .y(vga_scan_y),
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