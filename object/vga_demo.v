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
    
    // State definitions for both FSMs
    parameter INIT = 3'b000;
    parameter DRAW_GRID = 3'b001;
    parameter MOVE = 3'b010;
    
    // Memory array for pixel storage
    reg [0:0] pixel_memory [0:783];
    
    // Cursor position registers
    // Initially set to the middle
    reg [4:0] current_x = 5'd14;
    reg [4:0] current_y = 5'd14;
    
    // Button press detection
    reg [3:0] key_prev;
    wire [3:0] key_pressed = ~KEY & ~key_prev;
    
    // Movement control - Increased delay
    reg [19:0] move_delay = 20'd0;
    parameter DELAY_MAX = 20'd2000000;
    
    // Drawing control (goes into the VGA component)
    reg plot;
    reg [7:0] draw_x;
    reg [6:0] draw_y;
    
    // Inner pixel drawing control (used for temporary looping in a pixel chunk)
    reg [1:0] pixel_x_offset;
    reg [1:0] pixel_y_offset;
    
    // State registers for both FSMs
    reg [2:0] draw_state;
    reg [2:0] move_state;
    
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
        // Initialize the memory to zero
        for(i = 0; i < 784; i = i + 1) begin
            pixel_memory[i] <= 1'b0;
        end
        key_prev <= 4'b1111;
        draw_state <= INIT;
        move_state <= INIT;
        draw_x <= 8'd0;
        draw_y <= 7'd0;
        pixel_x_offset <= 2'b00;
        pixel_y_offset <= 2'b00;
        plot <= 1'b0;
    end
    
    // Movement FSM
    always @(posedge CLOCK_50) begin
        case(move_state)
            INIT: begin
                current_x <= 5'd14;
                current_y <= 5'd14;
                move_state <= MOVE;
            end
            
            MOVE: begin
                key_prev <= ~KEY;
                
                if (!SW[9]) begin
                    move_delay <= 20'd0;
                    for(i = 0; i < 784; i = i + 1) begin
                        pixel_memory[i] <= 1'b0;
                    end
                    current_x <= 5'd14;
                    current_y <= 5'd14;
                end
                else begin
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
        endcase
    end

    // Drawing FSM
    always @(posedge CLOCK_50) begin
        case(draw_state)
            INIT: begin
                draw_x <= 8'd0;
                draw_y <= 7'd0;
                pixel_x_offset <= 2'b00;
                pixel_y_offset <= 2'b00;
                plot <= 1'b1;
                draw_state <= DRAW_GRID;
            end
            
            DRAW_GRID: begin

                if (draw_y < (GRID_SIZE * PIXEL_SIZE) && draw_x < (GRID_SIZE * PIXEL_SIZE)) begin
                    plot <= 1'b1;
                    // Rest of your DRAW_GRID logic
                    plot <= 1'b1;
                    // Increment pixel by pixel within a 4x4 block
                    if (pixel_x_offset == 2'b11) begin
                        pixel_x_offset <= 2'b00;
                        if (pixel_y_offset == 2'b11) begin
                            pixel_y_offset <= 2'b00;
                            // Move to next grid cell
                            draw_x <= draw_x + 1'd1;
                            
                            if (draw_x >= (GRID_SIZE * PIXEL_SIZE - 1)) begin
                                draw_x <= 8'd0;
                                draw_y <= draw_y + 1'd1;
                            end
                        end 
                        else begin
                            pixel_y_offset <= pixel_y_offset + 1'b1;
                        end
                    end 
                    else begin
                        pixel_x_offset <= pixel_x_offset + 1'b1;
                    end
                    
                    // Check if we've drawn the entire grid
                    if (draw_y >= (GRID_SIZE * PIXEL_SIZE - 1) && 
                        pixel_y_offset == 2'b11 && pixel_x_offset == 2'b11) begin
                        draw_x <= 8'd0;
                        draw_y <= 7'd0;
                    end
                end 
                
                else begin
                    plot <= 1'b0;
                end
                
            end
        endcase
    end

    // Color output logic - simplified
    wire [4:0] mem_x = draw_x[7:2]; // Divide by 4 to get memory position
    wire [4:0] mem_y = draw_y[6:2];
    wire is_cursor = (mem_x == current_x && mem_y == current_y);
    wire is_pixel_set = pixel_memory[mem_y * GRID_SIZE + mem_x];
    
    wire [2:0] colour_out = is_cursor ? 3'b100 :           // Red for cursor
                        is_pixel_set ? 3'b111 : 3'b001; // White for set pixels, dark blue for grid
    
    // VGA position calculation
    wire [7:0] actual_x = {draw_x[7:2], pixel_x_offset};
    wire [6:0] actual_y = {draw_y[6:2], pixel_y_offset};

    // VGA controller
    vga_adapter VGA (
        .resetn(1'b1),
        .clock(CLOCK_50),
        .colour(colour_out),
        .x(actual_x),
        .y(actual_y),
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