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
    
    reg [0:0] pixel_memory [0:783];
    reg [4:0] current_x, current_y;
    reg [3:0] key_prev;
    wire [3:0] key_pressed = ~KEY & ~key_prev;
    
    reg [19:0] move_delay;
    parameter DELAY_MAX = 20'd500000; // Increased delay for slower movement
    
    wire [7:0] vga_x;
    wire [6:0] vga_y;
    reg [2:0] color_out;
    
    // State machine for initialization
    reg [2:0] state;
    reg [4:0] init_x, init_y;
    reg [1:0] pixel_x, pixel_y;
    
    parameter STATE_INIT = 3'b000;
    parameter STATE_DRAW_GRID = 3'b001;
    parameter STATE_RUNNING = 3'b010;
    
    // Debug outputs
    assign LEDR[9] = SW[9];
    assign LEDR[8] = SW[1];
    assign LEDR[4:0] = current_x[4:0];
    
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
        state <= STATE_INIT;
        init_x <= 0;
        init_y <= 0;
        pixel_x <= 0;
        pixel_y <= 0;
    end
    
    // Movement and drawing logic
    always @(posedge CLOCK_50) begin
        key_prev <= ~KEY;
        
        case(state)
            STATE_INIT: begin
                state <= STATE_DRAW_GRID;
                init_x <= 0;
                init_y <= 0;
                pixel_x <= 0;
                pixel_y <= 0;
            end
            
            STATE_DRAW_GRID: begin
                // Draw current 4x4 pixel
                if(pixel_x == 2'b11 && pixel_y == 2'b11) begin
                    if(init_x == GRID_SIZE-1) begin
                        if(init_y == GRID_SIZE-1)
                            state <= STATE_RUNNING;
                        else begin
                            init_y <= init_y + 1;
                            init_x <= 0;
                        end
                    end
                    else
                        init_x <= init_x + 1;
                    pixel_x <= 0;
                    pixel_y <= 0;
                end
                else if(pixel_x == 2'b11) begin
                    pixel_x <= 0;
                    pixel_y <= pixel_y + 1;
                end
                else
                    pixel_x <= pixel_x + 1;
            end
            
            STATE_RUNNING: begin
                if(move_delay > 0)
                    move_delay <= move_delay - 1;
                
                if(move_delay == 0) begin
                    if(~KEY[0] && current_y < GRID_SIZE-1) begin
                        current_y <= current_y + 1;
                        move_delay <= DELAY_MAX;
                    end
                    else if(~KEY[1] && current_y > 0) begin
                        current_y <= current_y - 1;
                        move_delay <= DELAY_MAX;
                    end
                    else if(~KEY[2] && current_x < GRID_SIZE-1) begin
                        current_x <= current_x + 1;
                        move_delay <= DELAY_MAX;
                    end
                    else if(~KEY[3] && current_x > 0) begin
                        current_x <= current_x - 1;
                        move_delay <= DELAY_MAX;
                    end
                end
                
                if(SW[1])
                    pixel_memory[current_y * GRID_SIZE + current_x] <= 1'b1;
            end
        endcase
    end
    
    // VGA coordinate calculation
    wire [9:0] actual_x = vga_x - GRID_OFFSET_X;
    wire [9:0] actual_y = vga_y - GRID_OFFSET_Y;
    wire [4:0] grid_x = actual_x[9:2]; // Divide by 4 to get grid position
    wire [4:0] grid_y = actual_y[9:2];
    wire in_grid = (vga_x >= GRID_OFFSET_X) && 
                  (vga_x < GRID_OFFSET_X + GRID_SIZE * PIXEL_SIZE) &&
                  (vga_y >= GRID_OFFSET_Y) && 
                  (vga_y < GRID_OFFSET_Y + GRID_SIZE * PIXEL_SIZE);
    
    // Color output logic
    always @(*) begin
        if(in_grid) begin
            if(grid_x == current_x && grid_y == current_y)
                color_out = 3'b100; // Red cursor
            else if(pixel_memory[grid_y * GRID_SIZE + grid_x])
                color_out = 3'b000; // Black for drawn pixels
            else
                color_out = 3'b111; // White for grid
        end
        else
            color_out = 3'b000; // Black background
    end
    
    // VGA controller instance
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