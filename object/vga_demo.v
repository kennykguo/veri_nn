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
    
    // Movement control - Increased delay
    reg [19:0] move_delay = 20'd0;
    parameter DELAY_MAX = 20'd2000000; // Increased from 100000 to 2000000
    
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
                // Increment pixel offsets first
                if (pixel_x_offset == 2'b11) begin
                    pixel_x_offset <= 2'b00;
                    if (pixel_y_offset == 2'b11) begin
                        pixel_y_offset <= 2'b00;
                        // Move to next grid position
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
                    plot <= 1'b0;
                end
            end
            
            3'b010: begin
                // Movement state
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
    
    // VGA position calculation for actual drawing
    wire [7:0] actual_x = (draw_state == 3'b001) ? 
                         (draw_x + pixel_x_offset) : x;
    wire [6:0] actual_y = (draw_state == 3'b001) ? 
                         (draw_y + pixel_y_offset) : y;
    
    // Color output logic
    assign colour_out = (draw_state == 3'b001) ? 3'b111 : // White grid
                       ((x >= GRID_OFFSET_X && x < (GRID_OFFSET_X + GRID_SIZE * PIXEL_SIZE) &&
                         y >= GRID_OFFSET_Y && y < (GRID_OFFSET_Y + GRID_SIZE * PIXEL_SIZE)) ?
                        ((((x - GRID_OFFSET_X) / PIXEL_SIZE) == current_x && 
                          ((y - GRID_OFFSET_Y) / PIXEL_SIZE) == current_y) ?
                         3'b100 : // Red for cursor
                         (pixel_memory[((y - GRID_OFFSET_Y) / PIXEL_SIZE) * GRID_SIZE + 
                                     ((x - GRID_OFFSET_X) / PIXEL_SIZE)] ? 3'b000 : 3'b111)) :
                        3'b000);  // Black background
    
    // VGA controller
    vga_adapter VGA (
        .resetn(1'b1),
        .clock(CLOCK_50),
        .colour(colour_out),
        .x(actual_x),
        .y(actual_y),
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