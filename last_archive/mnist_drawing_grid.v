module mnist_drawing_grid(
    input CLOCK_50,    
    input reset,
    input [3:0] KEY,      // KEY[0] = down, KEY[1] = up, KEY[2] = left, KEY[3] = right
    input draw,  
    input on,         
    output wire [15:0] read_addr,
    output wire signed [31:0] data_out,
    output [7:0] VGA_R, VGA_G, VGA_B,
    output VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK,
    output [6:0] HEX0, HEX1, HEX2, HEX3,
    input [3:0] led_control
);

    // Grid constants (28x28)
    parameter GRID_SIZE = 28;
    parameter PIXEL_SIZE = 4;
    
    // State definitions
    parameter INIT = 3'b000;
    parameter DRAW_GRID = 3'b001;
    parameter MOVE = 3'b010;
    
    // Wire declarations for coordinate conversion
    wire [5:0] mem_x;
    wire [4:0] mem_y;
    
    // Cursor position registers
    reg [4:0] current_x;
    reg [4:0] current_y;
    
    // Movement and debounce control
    reg [19:0] move_delay;
    reg [19:0] debounce_counter [3:0];
    parameter DELAY_MAX = 20'd1000000;
    parameter DEBOUNCE_LIMIT = 20'd50000;
    
    // Drawing control
    reg plot;
    reg [7:0] draw_x;
    reg [6:0] draw_y;
    
    // Inner pixel drawing control
    reg [1:0] pixel_x_offset;
    reg [1:0] pixel_y_offset;
    
    // State registers
    reg [2:0] draw_state;
    reg [2:0] move_state;

    // Memory interface signals
    wire [15:0] write_addr;
    reg signed [31:0] data_in;
    wire write_enable;

    // Reset synchronization
    reg [2:0] reset_sync;
    wire reset_f;

    // KEY debouncing registers
    reg [3:0] key_reg1, key_reg2;
    reg [3:0] key_stable;
    wire [3:0] key_pressed;

    // Local pixel memory for VGA display
    reg [783:0] pixel_memory;

    // Synchronize reset
    always @(posedge CLOCK_50) begin
        reset_sync <= {reset_sync[1:0], reset};
    end
    assign reset_f = reset_sync[2];

    // Enhanced key debouncing
    integer i;
    always @(posedge CLOCK_50) begin
        if (reset_f) begin
            key_reg1 <= 4'hF;
            key_reg2 <= 4'hF;
            key_stable <= 4'hF;
            for (i = 0; i < 4; i++) begin
                debounce_counter[i] <= 0;
            end
        end else begin
            key_reg1 <= KEY;
            key_reg2 <= key_reg1;
            
            for (i = 0; i < 4; i++) begin
                if (key_reg1[i] != key_stable[i]) begin
                    if (debounce_counter[i] >= DEBOUNCE_LIMIT) begin
                        key_stable[i] <= key_reg1[i];
                        debounce_counter[i] <= 0;
                    end else begin
                        debounce_counter[i] <= debounce_counter[i] + 1;
                    end
                end else begin
                    debounce_counter[i] <= 0;
                end
            end
        end
    end
    

    assign key_pressed = ~key_stable & key_reg1;
    // Memory instantiation
    image_memory img_mem (
        .clk(CLOCK_50),
        .reset(reset_f),
        .write_addr(write_addr),
        .read_addr(read_addr),
        .data_in(data_in),
        .write_enable(write_enable),
        .data_out(data_out),
        .led_control(led_control)
    );

    // Memory write control
    assign write_enable = draw && on;
    assign write_addr = current_y * GRID_SIZE + current_x;

    // 7-segment displays
    hex_display hex0(current_x[3:0], HEX0);
    hex_display hex1({3'b000, current_x[4]}, HEX1);
    hex_display hex2(current_y[3:0], HEX2);
    hex_display hex3({3'b000, current_y[4]}, HEX3);

    // Memory address calculations
    assign mem_x = draw_x[7:2];
    assign mem_y = draw_y[6:2];

    // Movement and drawing control
    always @(posedge CLOCK_50) begin
        if (reset_f) begin
            current_x <= 5'd14;  // Center of grid
            current_y <= 5'd14;
            move_delay <= 20'd0;
            data_in <= 32'd0;
            
            // Reset pixel memory
            for(i = 0; i < 784; i = i + 1) begin
                pixel_memory[i] <= 1'b0;
            end
        end
        else if (on) begin
            if (move_delay == 0) begin
                // Movement control
                if (key_pressed[3] && current_x < (GRID_SIZE-1)) begin
                    current_x <= current_x + 1;
                    move_delay <= DELAY_MAX;
                end
                else if (key_pressed[2] && current_x > 0) begin
                    current_x <= current_x - 1;
                    move_delay <= DELAY_MAX;
                end
                else if (key_pressed[1] && current_y > 0) begin
                    current_y <= current_y - 1;
                    move_delay <= DELAY_MAX;
                end
                else if (key_pressed[0] && current_y < (GRID_SIZE-1)) begin
                    current_y <= current_y + 1;
                    move_delay <= DELAY_MAX;
                end
                
                // Drawing control
                if (draw) begin
                    data_in <= 32'sd1;
                    pixel_memory[current_y * GRID_SIZE + current_x] <= 1'b1;
                end else begin
                    data_in <= 32'sd0;
                end
            end
            else begin
                move_delay <= move_delay - 1;
            end
        end
    end

    // VGA Drawing FSM
    always @(posedge CLOCK_50) begin
        if (reset_f) begin
            draw_x <= 8'd0;
            draw_y <= 7'd0;
            pixel_x_offset <= 2'b00;
            pixel_y_offset <= 2'b00;
            plot <= 1'b1;
            draw_state <= INIT;
        end
        else if (on) begin
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
                    if (draw_y < (GRID_SIZE * PIXEL_SIZE) && 
                        draw_x < (GRID_SIZE * PIXEL_SIZE)) begin
                        plot <= 1'b1;

                        if (pixel_x_offset == 2'b11) begin
                            pixel_x_offset <= 2'b00;
                            if (pixel_y_offset == 2'b11) begin
                                pixel_y_offset <= 2'b00;
                                draw_x <= draw_x + 1'd1;
                                
                                if (draw_x >= (GRID_SIZE * PIXEL_SIZE - 1)) begin
                                    draw_x <= 8'd0;
                                    draw_y <= draw_y + 1'd1;
                                end
                            end else begin
                                pixel_y_offset <= pixel_y_offset + 1'b1;
                            end
                        end else begin
                            pixel_x_offset <= pixel_x_offset + 1'b1;
                        end
                        
                        if (draw_y >= (GRID_SIZE * PIXEL_SIZE - 1) && 
                            pixel_y_offset == 2'b11 && 
                            pixel_x_offset == 2'b11) begin
                            draw_x <= 8'd0;
                            draw_y <= 7'd0;
                        end
                    end else begin
                        plot <= 1'b0;
                    end
                end
                
                default: draw_state <= INIT;
            endcase
        end
    end

    // Color output logic
    wire is_cursor = (mem_x == current_x && mem_y == current_y);
    wire is_pixel_set = pixel_memory[mem_y * GRID_SIZE + mem_x];
    
    reg [2:0] colour_out;
    always @(posedge CLOCK_50) begin
        if (reset_f) begin
            colour_out <= 3'b001;  // Default background color
        end
        else if (on) begin
            if (is_cursor)
                colour_out <= 3'b100;  // Red cursor
            else if (is_pixel_set)
                colour_out <= 3'b111;  // White for set pixels
            else
                colour_out <= 3'b001;  // Dark blue for grid
        end
    end
    
    // VGA position calculation
    wire [7:0] actual_x = {draw_x[7:2], pixel_x_offset};
    wire [6:0] actual_y = {draw_y[6:2], pixel_y_offset};

    // VGA controller instantiation
    vga_adapter VGA (
        .resetn(~reset_f),
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