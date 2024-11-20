module vga_demo(
    input CLOCK_50,    
    input [9:0] SW,
    input [3:0] KEY,
    output [7:0] VGA_R, VGA_G, VGA_B,
    output VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK,
    output [6:0] HEX0, HEX1, HEX2, HEX3,
    output [9:0] LEDR
);
    
    // Grid constants (28x28)
    parameter GRID_SIZE = 28;
    parameter PIXEL_SIZE = 4;
    parameter GRID_OFFSET_X = 10;
    parameter GRID_OFFSET_Y = 10;
    
    // Memory array for pixel storage
    reg [0:0] pixel_memory [0:783];
    
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
    wire [7:0] x;
    wire [6:0] y;
    wire [2:0] colour_out;
    
    // Drawing control
    reg plot;
    reg [7:0] draw_x;
    reg [6:0] draw_y;
    
    // Inner pixel drawing control
    reg [1:0] pixel_x_offset;
    reg [1:0] pixel_y_offset;
    
    // Drawing pixel state
    reg [2:0] pixel_draw_state;
    reg [1:0] draw_pixel_x;
    reg [1:0] draw_pixel_y;
    
    // State machine for drawing background
    reg [2:0] draw_state;
    reg [4:0] grid_x, grid_y;
    
    // Debug signals
    assign LEDR[9] = SW[9];
    assign LEDR[8] = SW[1];
    assign LEDR[4:0] = current_x[4:0];
    
    // Seven-segment display for coordinates
    hex_display hex0(current_x[3:0], HEX0);
    hex_display hex1({3'b000, current_x[4]}, HEX1);
    hex_display hex2(current_y[3:0], HEX2);
    hex_display hex3({3'b000, current_y[4]}, HEX3);
    
    // Initialize memory and registers
    integer i;
    initial begin
        for(i = 0; i < 784; i = i + 1) begin
            pixel_memory[i] <= 1'b0;
        end
        key_prev <= 4'b1111;
        draw_state <= 3'b000;
        draw_x <= GRID_OFFSET_X;
        draw_y <= GRID_OFFSET_Y;
        pixel_x_offset <= 2'b00;
        pixel_y_offset <= 2'b00;
        pixel_draw_state <= 3'b000;
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
                pixel_x_offset <= 2'b00;
                pixel_y_offset <= 2'b00;
                draw_state <= 3'b001;
                plot <= 1'b1;
            end
            
            3'b001: begin
                if (pixel_x_offset == 2'b11) begin
                    pixel_x_offset <= 2'b00;
                    if (pixel_y_offset == 2'b11) begin
                        pixel_y_offset <= 2'b00;
                        draw_x <= draw_x + PIXEL_SIZE;
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
                
                if (draw_y >= (GRID_OFFSET_Y + GRID_SIZE * PIXEL_SIZE - PIXEL_SIZE) && 
                    pixel_y_offset == 2'b11 && pixel_x_offset == 2'b11) begin
                    draw_state <= 3'b010;
                    pixel_draw_state <= 3'b000;
                    plot <= 1'b0;
                end
            end
            
            3'b010: begin
                // Movement and drawing state
                case(pixel_draw_state)
                    3'b000: begin  // Idle state
                        draw_pixel_x <= 2'b00;
                        draw_pixel_y <= 2'b00;
                        if (SW[1]) pixel_draw_state <= 3'b001;
                    end
                    
                    3'b001: begin  // Drawing state
                        plot <= 1'b1;
                        // Calculate absolute screen position
                        draw_x <= GRID_OFFSET_X + (current_x * PIXEL_SIZE) + draw_pixel_x;
                        draw_y <= GRID_OFFSET_Y + (current_y * PIXEL_SIZE) + draw_pixel_y;
                        pixel_draw_state <= 3'b010;
                    end
                    
                    3'b010: begin  // Update pixel coordinates
                        plot <= 1'b0;
                        if (draw_pixel_x == 2'b11) begin
                            draw_pixel_x <= 2'b00;
                            if (draw_pixel_y == 2'b11) begin
                                pixel_draw_state <= 3'b000;
                                pixel_memory[current_y * GRID_SIZE + current_x] <= 1'b1;
                            end else begin
                                draw_pixel_y <= draw_pixel_y + 1'b1;
                                pixel_draw_state <= 3'b001;
                            end
                        end else begin
                            draw_pixel_x <= draw_pixel_x + 1'b1;
                            pixel_draw_state <= 3'b001;
                        end
                    end
                endcase
            end
        endcase
    end
    
    // Movement logic
    always @(posedge CLOCK_50) begin
        if (draw_state == 3'b010 && pixel_draw_state == 3'b000) begin
            if (!SW[9]) begin
                move_delay <= 20'd0;
                for(i = 0; i < 784; i = i + 1) begin
                    pixel_memory[i] <= 1'b0;
                end
                current_x <= 5'd14;
                current_y <= 5'd14;
            end
            else begin
                key_prev <= ~KEY;
                
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
                end
                else begin
                    move_delay <= move_delay - 1'd1;
                end
            en