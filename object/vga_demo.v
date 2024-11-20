module vga_demo(
    input CLOCK_50,    
    input [9:0] SW,
    input [3:0] KEY,
    output [6:0] HEX3, HEX2, HEX1, HEX0,
    output [7:0] VGA_R, VGA_G, VGA_B,
    output VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK,
    output [9:0] LEDR
);
    
    // Grid constants (28x28)
    parameter GRID_SIZE = 28;
    parameter PIXEL_SIZE = 4;  // Reduced for 160x120 resolution
    parameter GRID_OFFSET_X = 10;
    parameter GRID_OFFSET_Y = 10;
    
    // Memory array for pixel storage
    reg [0:0] pixel_memory [0:783]; // 28x28 = 784 pixels
    
    // Cursor position registers
    reg [4:0] current_x = 5'd14;
    reg [4:0] current_y = 5'd14;
    
    // Button press detection
    reg [3:0] key_prev;
    wire [3:0] key_pressed = ~KEY & ~key_prev;
    
    // Movement control
    reg [19:0] move_delay = 20'd0;
    parameter DELAY_MAX = 20'd100000;
    
    // VGA signals
    wire [7:0] x;  // Changed to 8-bit for 160x120
    wire [6:0] y;  // Changed to 7-bit for 160x120
    wire [2:0] colour_out;  // Final output color
    reg [2:0] grid_colour;  // Color from grid logic
    
    // Drawing control
    reg plot;
    reg [7:0] draw_x;
    reg [6:0] draw_y;
    
    // State machine for drawing background
    reg [2:0] draw_state;
    reg [4:0] grid_x, grid_y;
    
    // Debug register
    reg [3:0] debug_state;
    
    // Initialize memory and registers
    integer i;
    initial begin
        for(i = 0; i < 784; i = i + 1) begin
            pixel_memory[i] <= 1'b0;
        end
        key_prev <= 4'b1111;
        debug_state <= 4'b0000;
        draw_state <= 3'b000;
        draw_x <= GRID_OFFSET_X;
        draw_y <= GRID_OFFSET_Y;
        plot <= 1'b0;
    end
    
    // Background drawing state machine
    always @(posedge CLOCK_50) begin
        case(draw_state)
            3'b000: begin
                draw_x <= GRID_OFFSET_X;
                draw_y <= GRID_OFFSET_Y;
                grid_x <= 5'b00000;
                grid_y <= 5'b00000;
                draw_state <= 3'b001;
                plot <= 1'b1;
            end
            
            3'b001: begin
                grid_colour <= 3'b111;  // White background
                
                draw_x <= draw_x + PIXEL_SIZE;
                if (draw_x >= (GRID_OFFSET_X + GRID_SIZE * PIXEL_SIZE - 1)) begin
                    draw_x <= GRID_OFFSET_X;
                    draw_y <= draw_y + PIXEL_SIZE;
                end
                
                if (draw_y >= (GRID_OFFSET_Y + GRID_SIZE * PIXEL_SIZE - 1)) begin
                    draw_state <= 3'b010;
                    plot <= 1'b0;
                end
            end
            
            3'b010: begin
                if (!SW[9]) begin
                    current_x <= 5'd14;
                    current_y <= 5'd14;
                end
            end
        endcase
    end
    
    // Movement and drawing logic
    always @(posedge CLOCK_50) begin
        if (draw_state == 3'b010) begin
            if (!SW[9]) begin
                move_delay <= 20'd0;
                for(i = 0; i < 784; i = i + 1) begin
                    pixel_memory[i] <= 1'b0;
                end
                debug_state <= 4'b0001;
            end
            else begin
                key_prev <= ~KEY;
                debug_state <= 4'b0010;
                
                if (move_delay == 0) begin
                    if (key_pressed[3] && current_x < (GRID_SIZE-1)) begin
                        current_x <= current_x + 1'd1;
                        move_delay <= DELAY_MAX;
                    end
                    if (key_pressed[2] && current_x > 0) begin
                        current_x <= current_x - 1'd1;
                        move_delay <= DELAY_MAX;
                    end
                    if (key_pressed[1] && current_y > 0) begin
                        current_y <= current_y - 1'd1;
                        move_delay <= DELAY_MAX;
                    end
                    if (key_pressed[0] && current_y < (GRID_SIZE-1)) begin
                        current_y <= current_y + 1'd1;
                        move_delay <= DELAY_MAX;
                    end
                    
                    if (SW[1]) begin
                        pixel_memory[current_y * GRID_SIZE + current_x] <= 1'b1;
                    end
                end
                else begin
                    move_delay <= move_delay - 1'd1;
                end
            end
        end
    end
    
    // Grid color logic
    always @(*) begin
        if (x >= GRID_OFFSET_X && x < (GRID_OFFSET_X + GRID_SIZE * PIXEL_SIZE) &&
            y >= GRID_OFFSET_Y && y < (GRID_OFFSET_Y + GRID_SIZE * PIXEL_SIZE)) begin
            
            grid_x = (x - GRID_OFFSET_X) / PIXEL_SIZE;
            grid_y = (y - GRID_OFFSET_Y) / PIXEL_SIZE;
            
            if (grid_x == current_x && grid_y == current_y) begin
                grid_colour = pixel_memory[grid_y * GRID_SIZE + grid_x] ? 3'b001 : 3'b100;
            end else begin
                grid_colour = pixel_memory[grid_y * GRID_SIZE + grid_x] ? 3'b000 : 3'b111;
            end
        end
        else begin
            grid_colour = 3'b111;  // White background
        end
    end
    
    // Color multiplexer
    assign colour_out = (draw_state == 3'b001) ? 3'b111 : grid_colour;
    
    // VGA controller
    vga_adapter VGA (
        .resetn(1'b1),
        .clock(CLOCK_50),
        .colour(colour_out),
        .x(draw_state == 3'b001 ? draw_x : x),
        .y(draw_state == 3'b001 ? draw_y : y),
        .plot(draw_state == 3'b001 ? 1'b1 : plot),
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